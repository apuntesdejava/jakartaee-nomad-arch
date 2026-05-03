#!/bin/bash
set -e

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Esperando a que Nomad esté listo..."
for i in {1..60}; do
  if nomad status &>/dev/null; then
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✓ Nomad está listo"
    break
  fi
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] Intento $i/60... esperando Nomad"
  sleep 2
done

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Configurando Consul KV con payara-resources..."
# Cargar configuración en Consul KV
consul kv put configs/payara-resources "$(cat /opt/payara-resources-prod.xml)" || echo "⚠️ No se pudo cargar en Consul"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] Desplegando jobs en Nomad..."

# Desplegar jobs
nomad job run -var "network_mode=host" /opt/nomad-jobs/clients.nomad && \
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✓ Job 'clients-backend' desplegado" || \
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✗ Error desplegando 'clients-backend'"

nomad job run -var "network_mode=host" /opt/nomad-jobs/products.nomad && \
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✓ Job 'products-backend' desplegado" || \
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✗ Error desplegando 'products-backend'"

nomad job run -var "network_mode=host" /opt/nomad-jobs/sales.nomad && \
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✓ Job 'sales-backend' desplegado" || \
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✗ Error desplegando 'sales-backend'"

echo "[$(date +'%Y-%m-%d %H:%M:%S')] ✓ Todos los jobs desplegados"
nomad job status
