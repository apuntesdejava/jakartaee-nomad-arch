#!/bin/bash
set -e

# ── Versiones a instalar ─────────────────────────────────────
CONSUL_VERSION="1.22.6"
NOMAD_VERSION="1.11.3"
VAULT_VERSION="1.21.4"   # opcional, para cuando uses secrets

ARCH="linux_amd64"
INSTALL_DIR="/usr/local/bin"
TMP_DIR=$(mktemp -d)

# ── Colores para output ──────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check() { command -v "$1" &>/dev/null; }
info()  { echo -e "${GREEN}✓${NC} $1"; }
warn()  { echo -e "${YELLOW}!${NC} $1"; }

cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

# ── Dependencias del sistema ─────────────────────────────────
echo "── Verificando dependencias..."
sudo apt-get update -qq
sudo apt-get install -y -qq curl unzip jq

# Docker Compose: solo instalar si no viene ya de Docker Desktop (WSL)
if docker compose version &>/dev/null 2>&1; then
  info "docker compose ya disponible (Docker Desktop WSL), omitiendo."
else
  warn "docker compose no encontrado, intentando instalar..."
  sudo apt-get install -y -qq docker-compose-plugin || \
    warn "No se pudo instalar docker-compose-plugin. Instala Docker Desktop para Windows con integración WSL."
fi
# ── Función de instalación genérica ─────────────────────────
install_hc_tool() {
  local name=$1
  local version=$2
  local binary="$INSTALL_DIR/$name"

  if check "$name"; then
    local current
    current=$("$name" version 2>/dev/null | head -1 | grep -oP '\d+\.\d+\.\d+' | head -1)
    if [ "$current" = "$version" ]; then
      info "$name $version ya instalado, omitiendo."
      return
    else
      warn "$name $current instalado, actualizando a $version..."
    fi
  fi

  local url="https://releases.hashicorp.com/${name}/${version}/${name}_${version}_${ARCH}.zip"
  echo "── Descargando $name $version..."
  curl -fsSL "$url" -o "$TMP_DIR/${name}.zip"
  unzip -q "$TMP_DIR/${name}.zip" -d "$TMP_DIR"
  sudo install -m 755 "$TMP_DIR/$name" "$INSTALL_DIR/$name"
  info "$name $version instalado en $INSTALL_DIR/$name"
}

# ── Instalar herramientas ────────────────────────────────────
install_hc_tool "consul" "$CONSUL_VERSION"
install_hc_tool "nomad"  "$NOMAD_VERSION"
install_hc_tool "vault"  "$VAULT_VERSION"

# ── CNI plugins (requerido por Nomad para el service mesh) ───
CNI_VERSION="v1.6.2"
CNI_DIR="/opt/cni/bin"

if [ -f "$CNI_DIR/bridge" ]; then
  info "CNI plugins ya instalados, omitiendo."
else
  echo "── Instalando CNI plugins (necesario para Consul Connect)..."
  sudo mkdir -p "$CNI_DIR"
  curl -fsSL "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz" \
    | sudo tar -xz -C "$CNI_DIR"
  info "CNI plugins instalados en $CNI_DIR"
fi

# ── Configuración del sistema para Nomad ────────────────────
echo "── Configurando parámetros del sistema..."

# Nomad necesita esto para los sidecars de Envoy
if ! grep -q "net.bridge.bridge-nf-call-arptables" /etc/sysctl.conf 2>/dev/null; then
  cat <<EOF | sudo tee -a /etc/sysctl.conf > /dev/null

# Requerido por Nomad bridge networking
net.bridge.bridge-nf-call-arptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
EOF
  sudo sysctl -p &>/dev/null || true
  info "Parámetros de red configurados."
fi
# ── iptables (requerido por Nomad bridge networking en WSL) ──
echo "── Configurando iptables..."
sudo apt-get install -y -qq iptables

sudo update-alternatives --set iptables /usr/sbin/iptables-legacy
sudo update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy
info "iptables-legacy configurado."
# Agregar usuario actual al grupo docker si no está
#if ! groups "$USER" | grep -q docker; then
#  sudo usermod -aG docker "$USER"
#  warn "Usuario agregado al grupo docker. Necesitas cerrar y reabrir la sesión WSL una vez."
#fi

# ── Verificación final ───────────────────────────────────────
echo ""
echo "── Versiones instaladas:"
consul version | head -1
nomad  version | head -1
vault  version | head -1
echo ""
info "Instalación completa. Ya puedes ejecutar ./start-local.sh"