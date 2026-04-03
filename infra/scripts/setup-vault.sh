#!/bin/bash
set -e

# Configuración por defecto (Vault en modo -dev usualmente escucha en 8200)
export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root'

echo "── Configurando Vault (KV y Políticas)..."

# 1. Habilitar motor de secretos KV v2 en la ruta 'kv'
if ! vault secrets list | grep -q "^kv/"; then
    echo "── Habilitando motor KV v2 en /kv..."
    vault secrets enable -path=kv kv-v2
else
    echo "── Motor KV v2 ya habilitado."
fi

# 2. Guardar credenciales de base de datos
echo "── Guardando credenciales de MySQL en kv/mysql..."
vault kv put kv/mysql \
    user="appuser" \
    password="apppass" \
    url="jdbc:mysql://host.docker.internal:3306/appdb?useSSL=false&allowPublicKeyRetrieval=true"

# 3. Configurar Workload Identities (JWT Auth)
echo "── Configurando JWT Auth para Nomad Workload Identities..."
if ! vault auth list | grep -q "^jwt/"; then
    vault auth enable jwt
fi

# Configurar el método JWT para confiar en Nomad
# En modo dev, Nomad sirve su JWKS en localhost:4646
vault write auth/jwt/config \
    jwks_url="http://localhost:4646/.well-known/jwks.json" \
    jwt_supported_algs="RS256" \
    default_role="nomad-cluster"

# Crear el ROLE en Vault que vincula Nomad con la política
echo "── Creando role 'nomad-cluster' en Vault..."
vault write auth/jwt/role/nomad-cluster - <<EOF
{
  "role_type": "jwt",
  "bound_audiences": ["vault.io"],
  "user_claim": "nomad_job_id",
  "token_policies": ["nomad-cluster"],
  "token_type": "service",
  "bound_claims": {
    "nomad_namespace": "default"
  }
}
EOF

# 4. Crear política para Nomad (mejorada)
echo "── Creando política 'nomad-cluster'..."
vault policy write nomad-cluster - <<EOF
path "kv/data/mysql" {
  capabilities = ["read"]
}
path "auth/token/renew-self" {
  capabilities = ["update"]
}
path "auth/token/lookup-self" {
  capabilities = ["read"]
}
EOF

echo "✓ Vault configurado correctamente con Workload Identities."
