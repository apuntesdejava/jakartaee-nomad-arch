#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(cd "$INFRA_DIR/.." && pwd)"


# ── Detectar runtime de contenedores ─────────────────────────
#
# Orden de preferencia:
#
#   1. Podman nativo Linux/WSL
#   2. Podman instalado en Windows, accesible desde WSL
#   3. Docker
#
if command -v podman &>/dev/null; then
  CONTAINER_RUNTIME="podman"
elif command -v podman.exe &>/dev/null; then
  CONTAINER_RUNTIME="podman.exe"
elif command -v docker &>/dev/null; then
  CONTAINER_RUNTIME="docker"
else
  echo "✗ No se encontró Podman ni Docker."
  exit 1
fi

echo "── Runtime de contenedores: $CONTAINER_RUNTIME"


# ── Verificaciones previas ───────────────────────────────────
for tool in consul nomad vault; do
  if ! command -v "$tool" &>/dev/null; then
    echo "✗ '$tool' no encontrado."
    echo "  Ejecuta primero:"
    echo ""
    echo "    ./infra/scripts/install-hashicorp.sh"
    echo ""
    exit 1
  fi
done


# ── Verificar runtime ────────────────────────────────────────
if ! "$CONTAINER_RUNTIME" info &>/dev/null; then
  echo "✗ $CONTAINER_RUNTIME no está disponible."

  if [ "$CONTAINER_RUNTIME" = "podman.exe" ]; then
    echo ""
    echo "  Desde PowerShell verifica que Podman Machine esté iniciado:"
    echo ""
    echo "    podman machine start"
    echo ""
  fi

  exit 1
fi


echo "── Limpiando procesos anteriores en segundo plano..."

pkill -f "consul agent" || true
pkill -f "nomad agent" || true
pkill -f "vault server" || true

sleep 2


# ── 1. MySQL ─────────────────────────────────────────────────
echo "── 1. Preparando MySQL..."


# Cuando Podman está instalado en Windows, NO ejecutamos
# "podman.exe compose" desde WSL.
#
# El proveedor Compose es un ejecutable Windows y las rutas
# /mnt/c/... pueden ser interpretadas incorrectamente como
# C:\mnt\c\...
#
# En ese caso MySQL debe levantarse previamente desde PowerShell.
#
if [ "$CONTAINER_RUNTIME" = "podman.exe" ]; then

  echo "── Verificando MySQL en Podman Windows..."

  if ! podman.exe ps \
      --format "{{.Names}}" \
      | tr -d '\r' \
      | grep -q "^mysql-dev$"; then

    echo ""
    echo "✗ El contenedor 'mysql-dev' no está corriendo."
    echo ""
    echo "  Desde PowerShell, en la raíz del proyecto, ejecuta:"
    echo ""
    echo "    podman compose -f .\\infra\\compose.yaml up -d"
    echo ""
    echo "  Después vuelve a ejecutar este script desde WSL."
    echo ""

    exit 1
  fi

  echo "✓ mysql-dev ya está corriendo en Podman Windows."

else

  # Podman o Docker ejecutándose nativamente dentro de Linux/WSL.
  echo "── Levantando MySQL con $CONTAINER_RUNTIME Compose..."

  "$CONTAINER_RUNTIME" compose \
    -f "$INFRA_DIR/compose.yaml" \
    up -d

fi


# ── Esperar a MySQL ──────────────────────────────────────────
echo "── Esperando que MySQL esté listo..."

until "$CONTAINER_RUNTIME" exec mysql-dev \
  mysqladmin ping \
  -h localhost \
  -uappuser \
  -papppass \
  --silent \
  2>/dev/null; do

  printf "."
  sleep 2

done

echo " listo."


# ── 2. Vault ─────────────────────────────────────────────────
echo "── 2. Arrancando Vault (modo dev)..."

vault server -dev \
  -dev-root-token-id="root" \
  -dev-listen-address="0.0.0.0:8200" \
  > /tmp/vault.log 2>&1 &


echo "── Esperando que Vault esté listo..."

until vault status \
  -address="http://127.0.0.1:8200" \
  &>/dev/null; do

  printf "."
  sleep 1

done

echo " listo."


# ── 3. Consul ────────────────────────────────────────────────
echo "── 3. Arrancando Consul..."

consul agent -dev \
  -node=local-node \
  -bind=127.0.0.1 \
  -client=0.0.0.0 \
  > /tmp/consul.log 2>&1 &


echo "── Esperando que Consul esté listo..."

until consul members &>/dev/null 2>&1; do

  printf "."
  sleep 1

done

echo " listo."


# ── 4. Nomad ─────────────────────────────────────────────────
echo "── 4. Arrancando Nomad..."

# Nomad necesita comunicarse con Vault durante la demo.
export VAULT_TOKEN="root"
export VAULT_ADDR="http://127.0.0.1:8200"


sudo -E nomad agent -dev \
  -config="$INFRA_DIR/nomad/agent-dev.hcl" \
  -dev-connect \
  -bind=0.0.0.0 \
  > /tmp/nomad.log 2>&1 &


echo "── Esperando que Nomad esté listo..."

until nomad status &>/dev/null 2>&1; do

  printf "."
  sleep 1

done

echo " listo."


# ── Configuración de Payara en Consul KV ─────────────────────
echo "── Cargando configuraciones en Consul KV..."

consul kv put \
  configs/payara-resources \
  @"$PROJECT_ROOT/sales-hc-example/local-setup/payara-resources-prod.xml"


# ── Configuración de Vault ───────────────────────────────────
echo "── Configurando secretos y políticas en Vault (Workload Identity)..."

bash "$SCRIPT_DIR/setup-vault.sh"


# ── 5. Config entries de Consul ──────────────────────────────
echo "── 5. Configurando Consul..."

# No se requieren rutas estáticas.
# Fabio descubre los servicios mediante los tags registrados
# por los jobs de Nomad en Consul.


# ── 6. Jobs Nomad ────────────────────────────────────────────
echo "── 6. Desplegando jobs..."

nomad job run -detach \
  "$INFRA_DIR/nomad/clients.nomad"

nomad job run -detach \
  "$INFRA_DIR/nomad/products.nomad"

nomad job run -detach \
  "$INFRA_DIR/nomad/sales.nomad"

nomad job run -detach \
  "$INFRA_DIR/nomad/api-gateway.nomad"


# ── Listo ────────────────────────────────────────────────────
echo ""
echo "✓ Stack listo (modo local con Vault)"
echo ""

echo "  Runtime:   $CONTAINER_RUNTIME"
echo ""

echo "  clients:   http://localhost:8081/clients/api"
echo "  products:  http://localhost:8082/products/api"
echo "  sales:     http://localhost:8083"
echo ""

echo "  Gateway:   http://localhost:8000"
echo "  Fabio UI:  http://localhost:9998"
echo ""

echo "  Vault UI:  http://localhost:8200 (token: root)"
echo "  Nomad UI:  http://localhost:4646"
echo "  Consul UI: http://localhost:8500"
echo ""

echo "  MySQL:     localhost:3306 (appuser/apppass)"
echo ""

echo "  Logs:"
echo "    /tmp/vault.log"
echo "    /tmp/consul.log"
echo "    /tmp/nomad.log"
echo ""