# ============================================================================
# Azure Configuration
# ============================================================================

location = "eastus"
prefix   = "nomad-j"

# ============================================================================
# Virtual Machine Configuration
# ============================================================================

admin_username = "azureuser"
admin_password = "ChangeMe!1234567890"  # CAMBIAR CON UNA CONTRASEÑA FUERTE
vm_size        = "Standard_B2s"

# ============================================================================
# Security Configuration
# ============================================================================

# Cambia esto a tu IP pública si quieres restringir SSH a una máquina específica
# Déjalo en "0.0.0.0/0" solo para testing rápido
allowed_ssh_cidr = "0.0.0.0/0"

# ============================================================================
# Database Configuration
# ============================================================================

mysql_user          = "appuser"
mysql_password      = "apppass123!"  # CAMBIAR CON UNA CONTRASEÑA FUERTE
mysql_root_password = "rootpass123!"  # CAMBIAR CON UNA CONTRASEÑA FUERTE

# ============================================================================
# Optional Features
# ============================================================================

# Establecer a true si quieres usar Azure Container Registry
# Normalmente no es necesario para dev si usas imágenes públicas
enable_acr = false

# ============================================================================
# Resource Tags
# ============================================================================

environment_tags = {
  Environment = "dev"
  Project     = "jakartaee-nomad"
  ManagedBy   = "Terraform"
  Owner       = "DevTeam"
}

