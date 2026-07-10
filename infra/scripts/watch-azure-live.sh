#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"
TERRAFORM_DIR="$INFRA_DIR/terraform"

INTERVAL="${INTERVAL:-5}"
CONTROL_IP="${CONTROL_IP:-}"
GATEWAY_IP="${GATEWAY_IP:-}"
SSH_TARGET="${SSH_TARGET:-}"

tfvar() {
  local name="$1"
  awk -F= -v key="$name" '
    $1 ~ "^[[:space:]]*" key "[[:space:]]*$" {
      value=$2
      sub(/#.*/, "", value)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", value)
      gsub(/^"|"$/, "", value)
      print value
      exit
    }
  ' "$TERRAFORM_DIR/terraform.tfvars"
}

if [ -z "$CONTROL_IP" ]; then
  CONTROL_IP="$(terraform -chdir="$TERRAFORM_DIR" output -raw control_public_ip)"
fi

if [ -z "$GATEWAY_IP" ]; then
  GATEWAY_IP="$(terraform -chdir="$TERRAFORM_DIR" output -raw gateway_public_ip)"
fi

if [ -z "$SSH_TARGET" ]; then
  ADMIN_USER="$(tfvar admin_username)"
  SSH_TARGET="${ADMIN_USER:-azureuser}@$CONTROL_IP"
fi

while true; do
  clear
  echo "JakartaEE Nomad demo - live infra watch"
  echo "Time:        $(date '+%Y-%m-%d %H:%M:%S')"
  echo "Control:     $SSH_TARGET"
  echo "Gateway:     http://$GATEWAY_IP:8000"
  echo "Fabio UI:    http://$GATEWAY_IP:9998"
  echo ""

  echo "== Nomad nodes =="
  ssh -o BatchMode=yes -o ConnectTimeout=5 "$SSH_TARGET" "nomad node status" || true
  echo ""

  echo "== Nomad jobs =="
  ssh -o BatchMode=yes -o ConnectTimeout=5 "$SSH_TARGET" "nomad job status | sed -n '1,12p'" || true
  echo ""

  echo "== Service health =="
  ssh -o BatchMode=yes -o ConnectTimeout=5 "$SSH_TARGET" "consul catalog services | grep -E 'backend|fabio' || true; echo; consul health checks -state any | grep -E 'ServiceName|Status|Output' | head -80" || true
  echo ""

  echo "== Gateway probes =="
  for path in \
    "/clients/api/q/health/ready" \
    "/products/api/q/health/ready" \
    "/sales/resources/sale"; do
    code="$(curl -sS -m 3 -o /dev/null -w '%{http_code}' "http://$GATEWAY_IP:8000$path" || true)"
    printf "%-36s %s\n" "$path" "$code"
  done
  echo ""

  echo "== Fabio UI probe =="
  curl -sS -m 3 -o /dev/null -w "http://$GATEWAY_IP:9998 -> %{http_code}\n" "http://$GATEWAY_IP:9998" || true
  echo ""
  echo "Refresh cada ${INTERVAL}s. Ctrl+C para salir."

  sleep "$INTERVAL"
done
