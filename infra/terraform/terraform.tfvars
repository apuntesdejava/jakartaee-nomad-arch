# ============================================================================
# Azure Configuration
# ============================================================================

resource_group_name = "jakartaee-nomad-demo-rg"
location            = "westeurope"

# ============================================================================
# Virtual Machine Configuration
# ============================================================================

vm_size              = "Standard_B2s"
admin_username       = "azureuser"
admin_ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCaN103RiDvN2mo1kYVAn8ANe2fSYMOoZQQ0G4Jv4wEQa8SdmMCNkscYviUODeEDAxCkFl9zxxv8MHONjFType6tRtSf1gb3XtXkK2xatjhLabYKmtAkVFoU8fPVne3U9tRL5E1RbtBs5UTo0Vzl86zl+u/2uEKuTdYgMpkm0zUOvhH0HFqmLQa1Sc4bmuDrPLlbpX7ayuKZLVQm5uutGBoXXihyayjcda0JLGsu0PboWW6EZZcYO/bMlW7dzJBpruGDxM2tIDByNW8FF9Kdkea9B3+wUch/pgz7FH39dZDFbpL42uq3pCnhEgLJ2d+/3Q+s66K4N4HjRH7tC1/jTz7 rsa-key-20260423"

# ============================================================================
# Security Configuration
# ============================================================================

# Cambia esto a tu IP pública para mayor seguridad
my_ip = "0.0.0.0/0" # Permite acceso desde cualquier lugar (dev)

# ============================================================================
# Database Configuration
# ============================================================================

mysql_server_name   = "jakartaee-nomad-mysql-v2" # Nuevo nombre para evitar conflictos con el estado fallido
mysql_root_password = "RootPassword123!"
mysql_user          = "appuser"
mysql_password      = "AppPassword123!"
