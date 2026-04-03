#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(cd "$INFRA_DIR/.." && pwd)"

# ── Verificaciones previas ───────────────────────────────────
for tool in consul nomad vault docker; do
  if ! command -v "$tool" &>/dev/null; then
    echo "✗ '$tool' no encontrado. Ejecuta primero: ./infra/scripts/install-hashicorp.sh"
    exit 1
  fi
done

if ! docker info &>/dev/null; then
  echo "✗ Docker no está corriendo. Verifica Docker Desktop en Windows."
  exit 1
fi

# ── 1. MySQL ─────────────────────────────────────────────────
echo "── 1. Levantando MySQL con Docker Compose..."
docker compose -f "$INFRA_DIR/compose.yaml" up -d

echo "── Esperando que MySQL esté listo..."
until docker exec mysql-dev \
  mysqladmin ping -h localhost -uappuser -papppass --silent 2>/dev/null; do
  printf "."
  sleep 2
done
echo " listo."

# ── 2. Vault ──────────────────────────────────────────────────
echo "── 2. Arrancando Vault (modo dev)..."
vault server -dev \
  -dev-root-token-id="root" \
  -dev-listen-address="0.0.0.0:8200" \
  > /tmp/vault.log 2>&1 &

echo "── Esperando que Vault esté listo..."
until vault status -address="http://127.0.0.1:8200" &>/dev/null; do
  printf "."
  sleep 1
done
echo " listo."

echo " listo."

# ── 3. Consul ────────────────────────────────────────────────
echo "── 3. Arrancando Consul..."
consul agent -dev \
  -node=local-node \
  -bind=127.0.0.1 \
  > /tmp/consul.log 2>&1 &

echo "── Esperando que Consul esté listo..."
until consul members &>/dev/null 2>&1; do
  printf "."
  sleep 1
done
echo " listo."

# ── 4. Nomad ─────────────────────────────────────────────────
echo "── 4. Arrancando Nomad..."
# Nomad necesita el token de Vault para comunicarse en modo dev
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

# Cargar configuración de Payara en Consul KV para que Nomad pueda leerla limpiamente
echo "── Cargando configuraciones en Consul KV..."
consul kv put configs/payara-resources @$PROJECT_ROOT/sales-hc-example/local-setup/payara-resources-prod.xml

echo "── Configurando secretos y políticas en Vault (Workload Identity)..."
bash "$SCRIPT_DIR/setup-vault.sh"

# ── 5. Config entries de Consul ──────────────────────────────
echo "── 5. Configurando Consul..."
consul config write "$INFRA_DIR/consul/api-gateway.hcl"
consul config write "$INFRA_DIR/consul/http-route.hcl"
consul config write "$INFRA_DIR/consul/intentions-clients.hcl"
consul config write "$INFRA_DIR/consul/intentions-products.hcl"
consul config write "$INFRA_DIR/consul/intentions-sales.hcl"

# ── 6. Jobs Nomad ────────────────────────────────────────────
echo "── 6. Desplegando jobs..."
nomad job run -var "project_root=$PROJECT_ROOT" "$INFRA_DIR/nomad/clients.nomad"
nomad job run -var "project_root=$PROJECT_ROOT" "$INFRA_DIR/nomad/products.nomad"
nomad job run -var "project_root=$PROJECT_ROOT" "$INFRA_DIR/nomad/sales.nomad"

# ── Listo ────────────────────────────────────────────────────
echo ""
echo "✓ Stack listo (modo local con Vault)"
echo "  clients:   http://localhost:8081/clients/api"
echo "  products:  http://localhost:8082/products/api"
echo "  sales:     http://localhost:8083"
echo "  Vault UI:  http://localhost:8200 (token: root)"
echo "  Nomad UI:  http://localhost:4646"
echo "  Consul UI: http://localhost:8500"
echo "  MySQL:     localhost:3306 (appuser/apppass)"
echo ""
echo "  Logs: /tmp/vault.log | /tmp/consul.log | /tmp/nomad.log"