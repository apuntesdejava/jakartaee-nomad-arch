vault {
  enabled = true
  address = "http://127.0.0.1:8200"
  token   = "root"
  jwt_auth_backend_path = "jwt"

  default_identity {
    aud = ["vault.io"]
    ttl = "1h"
  }
}
