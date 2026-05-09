#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INFRA_DIR="$(dirname "$SCRIPT_DIR")"
PROJECT_ROOT="$(cd "$INFRA_DIR/.." && pwd)"

CLOUD_IP=$1

if [ -z "$CLOUD_IP" ]; then
    echo "── Intentando obtener IP de la nube desde Terraform local..."
    cd "$INFRA_DIR/terraform"
    CLOUD_IP=$(terraform output -raw public_ip 2>/dev/null || echo "")
fi

if [ -z "$CLOUD_IP" ] || [ "$CLOUD_IP" == "No outputs found" ]; then
    echo "✗ Error: No se pudo detectar la IP automáticamente."
    echo "Uso: ./infra/scripts/deploy-cloud.sh <IP_PUBLICA_DE_AZURE>"
    exit 1
fi

echo "── IP de la nube: $CLOUD_IP"

export NOMAD_ADDR="http://$CLOUD_IP:4646"
export CONSUL_HTTP_ADDR="http://$CLOUD_IP:8500"

echo "── 1. Esperando que Nomad en la nube esté listo..."
# Cambiamos la espera a Nomad (puerto 4646) que ya vimos que responde
until curl -s --connect-timeout 2 "$NOMAD_ADDR/v1/status/leader" >/dev/null; do
    printf "."
    sleep 5
done
echo " listo."

echo "── 2. Cargando configuraciones en Consul KV en la nube..."
# Intentamos cargar en Consul. Si falla, es que Consul no abrió el puerto 8500 externamente
if ! consul kv put -http-addr="$CONSUL_HTTP_ADDR" configs/payara-resources "@$PROJECT_ROOT/sales-hc-example/local-setup/payara-resources-prod.xml"; then
    echo "⚠️  Advertencia: No se pudo conectar a Consul en $CONSUL_HTTP_ADDR."
    echo "Asegúrate de que el puerto 8500 esté abierto en el NSG de Azure."
    exit 1
fi

echo "── 3. Desplegando Jobs en Nomad Cloud..."
nomad job run -detach "$INFRA_DIR/nomad/api-gateway.nomad"
nomad job run -detach "$INFRA_DIR/nomad/clients.nomad"
nomad job run -detach "$INFRA_DIR/nomad/products.nomad"
nomad job run -detach "$INFRA_DIR/nomad/sales.nomad"

echo ""
echo "✓ ¡Despliegue completado con éxito!"
echo "  Nomad UI:    http://$CLOUD_IP:4646"
echo "  Consul UI:   http://$CLOUD_IP:8500"
echo "  Fabio UI:    http://$CLOUD_IP:9998"
echo "  Gateway API: http://$CLOUD_IP:8000"
echo "  Clients:     http://$CLOUD_IP:8000/clients/api"
echo "  Products:    http://$CLOUD_IP:8000/products/api"
echo "  Sales:       http://$CLOUD_IP:8000/sales"
echo ""
