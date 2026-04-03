#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"

# Lee el ACR y la IP de los outputs de Terraform
ACR=$(cd "$INFRA_DIR/terraform" && terraform output -raw acr_login_server)
NOMAD_HOST=$(cd "$INFRA_DIR/terraform" && terraform output -raw vm_public_ip)

export NOMAD_ADDR="http://$NOMAD_HOST:4646"
export CONSUL_HTTP_ADDR="http://$NOMAD_HOST:8500"

echo "── Desplegando en Azure ($NOMAD_HOST)..."

# ── Config entries de Consul ─────────────────────────────────
echo "── Configurando Consul..."
consul config write "$INFRA_DIR/consul/api-gateway.hcl"
consul config write "$INFRA_DIR/consul/http-route.hcl"
consul config write "$INFRA_DIR/consul/intentions-clients.hcl"
consul config write "$INFRA_DIR/consul/intentions-products.hcl"
consul config write "$INFRA_DIR/consul/intentions-sales.hcl"

# ── Jobs en bridge mode apuntando al ACR ────────────────────
echo "── Desplegando jobs..."
nomad job run \
  -var="registry=$ACR" \
  -var="network_mode=bridge" \
  -var="instance_count=1" \
  "$INFRA_DIR/nomad/clients.nomad"

nomad job run \
  -var="registry=$ACR" \
  -var="network_mode=bridge" \
  -var="instance_count=1" \
  "$INFRA_DIR/nomad/products.nomad"

nomad job run \
  -var="registry=$ACR" \
  -var="network_mode=bridge" \
  -var="instance_count=1" \
  "$INFRA_DIR/nomad/sales.nomad"

nomad job run \
  -var="network_mode=bridge" \
  "$INFRA_DIR/nomad/api-gateway.nomad"

echo ""
echo "✓ Stack listo (Azure)"
echo "  App:       http://$NOMAD_HOST:8080"
echo "  Nomad UI:  http://$NOMAD_HOST:4646"
echo "  Consul UI: http://$NOMAD_HOST:8500"