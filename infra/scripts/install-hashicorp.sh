#!/bin/bash
set -e

# ── Versiones a instalar ─────────────────────────────────────
CONSUL_VERSION="2.0.3"
NOMAD_VERSION="2.0.5" 
VAULT_VERSION="2.0.4" 
TERRAFORM_VERSION="1.15.5"

ARCH="linux_amd64"
INSTALL_DIR="/usr/local/bin"
TMP_DIR=$(mktemp -d)

# ── Colores para output ──────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

check() {
  command -v "$1" &>/dev/null
}

info() {
  echo -e "${GREEN}✓${NC} $1"
}

warn() {
  echo -e "${YELLOW}!${NC} $1"
}

cleanup() {
  rm -rf "$TMP_DIR"
}

trap cleanup EXIT


# ── Dependencias del sistema ─────────────────────────────────
echo "── Verificando dependencias..."

sudo apt-get update -qq
sudo apt-get install -y -qq curl unzip jq


# ── Runtimes Podman ──────────────────────────────────────────
echo "── Verificando runtime de contenedores..."

if ! command -v podman &>/dev/null; then
  warn "Podman nativo de Linux/WSL no está instalado."
  warn "Instálalo con:"
  echo "  sudo apt update"
  echo "  sudo apt install -y podman"
  exit 1
fi

if ! podman info &>/dev/null; then
  warn "Podman nativo de Linux/WSL está instalado, pero 'podman info' no responde."
  warn "Verifica la configuración de Podman antes de continuar."
  exit 1
fi

info "Podman nativo de Linux/WSL disponible."

if command -v podman.exe &>/dev/null; then
  if podman.exe info &>/dev/null; then
    info "Podman Windows disponible y respondiendo desde WSL."
  else
    warn "Podman Windows está instalado, pero no responde."
    warn "Ejecuta en PowerShell: podman machine start"
  fi
else
  warn "Podman Windows (podman.exe) no se detectó desde WSL."
fi

# ── Función de instalación genérica ─────────────────────────
install_hc_tool() {

  local name=$1
  local version=$2
  local binary="$INSTALL_DIR/$name"

  if check "$name"; then

    local current

    current=$(
      "$name" version 2>/dev/null |
      head -1 |
      grep -oP '\d+\.\d+\.\d+' |
      head -1
    )

    if [ "$current" = "$version" ]; then

      info "$name $version ya instalado, omitiendo."
      return

    else

      warn "$name $current instalado, actualizando a $version..."

    fi
  fi

  local url="https://releases.hashicorp.com/${name}/${version}/${name}_${version}_${ARCH}.zip"

  echo "── Descargando $name $version..."
  echo "   $url"

  curl -fsSLk "$url" \
    -o "$TMP_DIR/${name}.zip"

  unzip -q \
    "$TMP_DIR/${name}.zip" \
    -d "$TMP_DIR"

  sudo install \
    -m 755 \
    "$TMP_DIR/$name" \
    "$binary"

  info "$name $version instalado en $binary"
}


# ── Instalar herramientas HashiCorp ──────────────────────────
install_hc_tool "consul"     "$CONSUL_VERSION"
install_hc_tool "nomad"      "$NOMAD_VERSION"
install_hc_tool "vault"      "$VAULT_VERSION"
install_hc_tool "terraform"  "$TERRAFORM_VERSION"


# ── CNI plugins ──────────────────────────────────────────────
#
# Requeridos por Nomad para bridge networking / Consul Connect.
#
CNI_VERSION="v1.6.2"
CNI_DIR="/opt/cni/bin"

if [ -f "$CNI_DIR/bridge" ]; then

  info "CNI plugins ya instalados, omitiendo."

else

  echo "── Instalando CNI plugins..."

  sudo mkdir -p "$CNI_DIR"

  curl -fsSL \
    "https://github.com/containernetworking/plugins/releases/download/${CNI_VERSION}/cni-plugins-linux-amd64-${CNI_VERSION}.tgz" \
    | sudo tar -xz -C "$CNI_DIR"

  info "CNI plugins instalados en $CNI_DIR"

fi


# ── Configuración del sistema para Nomad ────────────────────
echo "── Configurando parámetros del sistema..."

if ! grep -q \
  "net.bridge.bridge-nf-call-arptables" \
  /etc/sysctl.conf \
  2>/dev/null; then

  cat <<EOF | sudo tee -a /etc/sysctl.conf > /dev/null

# Requerido por Nomad bridge networking
net.bridge.bridge-nf-call-arptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
EOF

  sudo sysctl -p &>/dev/null || true

  info "Parámetros de red configurados."

else

  info "Parámetros de bridge networking ya configurados."

fi


# ── iptables ─────────────────────────────────────────────────
#
# Nomad necesita iptables para bridge networking dentro de WSL.
#
echo "── Configurando iptables..."

sudo apt-get install \
  -y \
  -qq \
  iptables

if [ -x /usr/sbin/iptables-legacy ]; then
  sudo update-alternatives \
    --set iptables \
    /usr/sbin/iptables-legacy
fi

if [ -x /usr/sbin/ip6tables-legacy ]; then
  sudo update-alternatives \
    --set ip6tables \
    /usr/sbin/ip6tables-legacy
fi

info "iptables configurado."


# ── Verificación final ───────────────────────────────────────
echo ""
echo "── Versiones instaladas:"

consul version | head -1
nomad version  | head -1
vault version  | head -1
terraform version | head -1

echo ""


# ── Resumen de runtimes ──────────────────────────────────────
info "Runtime Nomad requerido: Podman Linux/WSL"
info "Runtime MySQL esperado: Podman Windows"


echo ""
info "Instalación completa."
echo ""
echo "Ya puedes ejecutar:"
echo ""
echo "  ./infra/scripts/start-local.sh"
echo ""
