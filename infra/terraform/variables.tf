variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "jakartaee-nomad-demo-rg"
}

variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "eastus"
}

variable "vm_size" {
  description = "Size of the Virtual Machine"
  type        = string
  default     = "Standard_B2s" # 2 vCPUs, 4GB RAM - Economical for demo
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "my_ip" {
  description = "Your public IP to restrict SSH and UI access (optional, defaults to allow all for demo simplicity)"
  type        = string
  default     = "0.0.0.0/0"
}
