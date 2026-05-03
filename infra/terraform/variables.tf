variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "jakartaee-nomad-demo-rg"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "vm_size" {
  description = "Size of the Virtual Machine"
  type        = string
  default     = "Standard_B2s"
}

variable "admin_username" {
  description = "Admin username"
  type        = string
  default     = "azureuser"
}

variable "my_ip" {
  description = "Your public IP"
  type        = string
  default     = "0.0.0.0/0"
}

variable "mysql_root_password" {
  description = "MySQL root password"
  type        = string
  default     = "rootpass"
}

variable "mysql_user" {
  description = "MySQL application user"
  type        = string
  default     = "appuser"
}

variable "mysql_password" {
  description = "MySQL application password"
  type        = string
  default     = "apppass"
}

variable "admin_ssh_public_key" {
  description = "Admin SSH public key"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCaN103RiDvN2mo1kYVAn8ANe2fSYMOoZQQ0G4Jv4wEQa8SdmMCNkscYviUODeEDAxCkFl9zxxv8MHONjFType6tRtSf1gb3XtXkK2xatjhLabYKmtAkVFoU8fPVne3U9tRL5E1RbtBs5UTo0Vzl86zl+u/2uEKuTdYgMpkm0zUOvhH0HFqmLQa1Sc4bmuDrPLlbpX7ayuKZLVQm5uutGBoXXihyayjcda0JLGsu0PboWW6EZZcYO/bMlW7dzJBpruGDxM2tIDByNW8FF9Kdkea9B3+wUch/pgz7FH39dZDFbpL42uq3pCnhEgLJ2d+/3Q+s66K4N4HjRH7tC1/jTz7 rsa-key-20260423"
}
