#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"

echo "── 1. Levantando MySQL con Docker Compose..."
docker compose -f "$INFRA_DIR/compose.yaml" up -d

#echo "── Esperando que MySQL esté listo..."
#until docker compose -f "$INFRA_DIR/compose.yml" exec -T mysql \
#  mysqladmin ping -h localhost -uappuser -papppass --silent 2>/dev/null; do
#  printf "."
#  sleep 2
#done
#echo " listo."

echo "── 2. Arrancando Consul..."
consul agent -dev \
  -node=local-node \
  -bind=127.0.0.1 \
  > /tmp/consul.log 2>&1 &
sleep 3

echo "── 3. Arrancando Nomad..."
sudo nomad agent -dev \
  -dev-connect \
  -bind=0.0.0.0 \
  > /tmp/nomad.log 2>&1 &
sleep 5

echo "── 4. Configurando Consul API Gateway..."
consul config write "$INFRA_DIR/consul/api-gateway.hcl"
consul config write "$INFRA_DIR/consul/http-route.hcl"
consul config write "$INFRA_DIR/consul/intentions-clients.hcl"
consul config write "$INFRA_DIR/consul/intentions-products.hcl"
consul config write "$INFRA_DIR/consul/intentions-sales.hcl"

echo "── 5. Desplegando jobs..."
nomad job run "$INFRA_DIR/nomad/clients.nomad"
nomad job run "$INFRA_DIR/nomad/products.nomad"
nomad job run "$INFRA_DIR/nomad/sales.nomad"
nomad job run "$INFRA_DIR/nomad/api-gateway.nomad"

echo ""
echo "✓ Stack listo"
echo "  App:       http://localhost:8080"
echo "  Nomad UI:  http://localhost:4646"
echo "  Consul UI: http://localhost:8500"
echo "  MySQL:     localhost:3306 (appuser/apppass)"