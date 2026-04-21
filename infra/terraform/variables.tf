variable "location" {
  description = "Región de Azure"
  type        = string
  default     = "swedencentral"
}

variable "prefix" {
  description = "Prefijo para los nombres de los recursos"
  type        = string
  default     = "nomad-j"
}

variable "admin_username" {
  description = "Usuario administrador de la VM"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Password para el usuario administrador"
  type        = string
  sensitive   = true
}

variable "vm_size" {
  description = "Tamaño de la VM"
  type        = string
  default     = "Standard_B2s"
}

variable "enable_acr" {
  description = "Habilitar Azure Container Registry (innecesario para dev con imágenes públicas)"
  type        = bool
  default     = false
}

variable "mysql_user" {
  description = "Usuario de MySQL"
  type        = string
  default     = "appuser"
}

variable "mysql_password" {
  description = "Password de MySQL"
  type        = string
  sensitive   = true
}

variable "mysql_root_password" {
  description = "Root password de MySQL"
  type        = string
  sensitive   = true
}

variable "allowed_ssh_cidr" {
  description = "CIDR permitido para SSH (usa tu IP pública o 0.0.0.0/0 solo en dev)"
  type        = string
  default     = "0.0.0.0/0"
}

variable "environment_tags" {
  description = "Tags para todos los recursos"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "jakartaee-nomad"
    ManagedBy   = "Terraform"
  }
}

