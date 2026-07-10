# Configuración adicional del agente Nomad local para integrarse con Vault.
# start-local.sh arranca Vault dev en 127.0.0.1:8200 y luego inicia Nomad con
# este archivo mediante "-config=infra/nomad/agent-dev.hcl".
vault {
  # Activa la integración Nomad/Vault para que los jobs puedan usar bloques
  # "vault" y templates con la función secret.
  enabled = true
  # Vault corre localmente en modo dev con token root durante la demo.
  address = "http://127.0.0.1:8200"
  token   = "root"
  # Backend JWT configurado por setup-vault.sh para Workload Identity.
  jwt_auth_backend_path = "jwt"

  # Identidad por defecto que Nomad emite para sus tareas. Vault valida esta
  # audiencia y TTL antes de entregar secretos a una allocation.
  default_identity {
    aud = ["vault.io"]
    ttl = "1h"
  }
}
