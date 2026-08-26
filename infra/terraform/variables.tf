variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "jakartaee-nomad-demo-rg"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "westeurope"
}

variable "vm_size" {
  description = "Size of the control-plane virtual machine"
  type        = string
  default     = "Standard_B2s"
}

variable "worker_vm_size" {
  description = "Size of each Nomad worker virtual machine"
  type        = string
  default     = "Standard_B2s"
}

variable "worker_count" {
  description = "Number of Nomad worker nodes in the VM Scale Set"
  type        = number
  default     = 3
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

variable "mysql_server_name" {
  description = "Globally unique name for the Azure Database for MySQL"
  type        = string
}

variable "manage_mysql" {
  description = "Whether this Terraform stack should create and manage Azure Database for MySQL. Set to false to reuse an existing server."
  type        = bool
  default     = true
}

variable "mysql_root_password" {
  description = "MySQL root password"
  type        = string
  default     = "RootPassword123!"
}

variable "mysql_user" {
  description = "MySQL application user"
  type        = string
  default     = "appuser"
}

variable "mysql_password" {
  description = "MySQL application password"
  type        = string
  default     = "AppPassword123!"
}

variable "mysql_sku" {
  description = "SKU for MySQL Flexible Server"
  type        = string
  default     = "B_Standard_B2s"
}

variable "nomad_version" {
  description = "Nomad version to install on Azure nodes"
  type        = string
  default     = "2.0.0"
}

variable "nomad_podman_driver_version" {
  description = "Nomad Podman task driver version to install on Azure worker nodes"
  type        = string
  default     = "0.6.5"
}

variable "consul_version" {
  description = "Consul version to install on Azure nodes"
  type        = string
  default     = "1.22.7"
}

variable "vault_version" {
  description = "Vault version to install on the control-plane node"
  type        = string
  default     = "2.0.0"
}

variable "admin_ssh_public_key" {
  description = "Admin SSH public key"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCaN103RiDvN2mo1kYVAn8ANe2fSYMOoZQQ0G4Jv4wEQa8SdmMCNkscYviUODeEDAxCkFl9zxxv8MHONjFType6tRtSf1gb3XtXkK2xatjhLabYKmtAkVFoU8fPVne3U9tRL5E1RbtBs5UTo0Vzl86zl+u/2uEKuTdYgMpkm0zUOvhH0HFqmLQa1Sc4bmuDrPLlbpX7ayuKZLVQm5uutGBoXXihyayjcda0JLGsu0PboWW6EZZcYO/bMlW7dzJBpruGDxM2tIDByNW8FF9Kdkea9B3+wUch/pgz7FH39dZDFbpL42uq3pCnhEgLJ2d+/3Q+s66K4N4HjRH7tC1/jTz7 rsa-key-20260423"
}
