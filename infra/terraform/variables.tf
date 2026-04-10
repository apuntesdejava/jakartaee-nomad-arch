variable "location" {
  description = "Región de Azure"
  type        = "string"
  default     = "East US"
}

variable "prefix" {
  description = "Prefijo para los nombres de los recursos"
  type        = "string"
  default     = "nomad-jakarta"
}

variable "admin_username" {
  description = "Usuario administrador de la VM"
  type        = "string"
  default     = "azureuser"
}

variable "admin_password" {
  description = "Password para el usuario administrador y MySQL"
  type        = "string"
  sensitive   = true
}
