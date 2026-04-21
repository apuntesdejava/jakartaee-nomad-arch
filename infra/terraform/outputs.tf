output "vm_public_ip" {
  description = "Public IP address of the VM"
  value       = azurerm_public_ip.main.ip_address
}

output "vm_private_ip" {
  description = "Private IP address of the VM"
  value       = azurerm_network_interface.main.private_ip_address
}

output "vm_ssh_command" {
  description = "SSH command to connect to the VM"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.main.ip_address}"
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "nomad_ui_url" {
  description = "URL to Nomad UI"
  value       = "http://${azurerm_public_ip.main.ip_address}:4646"
}

output "consul_ui_url" {
  description = "URL to Consul UI"
  value       = "http://${azurerm_public_ip.main.ip_address}:8500"
}

output "vault_ui_url" {
  description = "URL to Vault UI"
  value       = "http://${azurerm_public_ip.main.ip_address}:8200"
}

output "fabio_ui_url" {
  description = "URL to Fabio Admin UI"
  value       = "http://${azurerm_public_ip.main.ip_address}:9998"
}

output "fabio_http_url" {
  description = "Fabio HTTP endpoint (for application routing)"
  value       = "http://${azurerm_public_ip.main.ip_address}:9999"
}

output "mysql_connection_string" {
  description = "MySQL connection string (running in Docker on VM)"
  value       = "mysql://${var.mysql_user}:${var.mysql_password}@${azurerm_public_ip.main.ip_address}:3306/appdb"
  sensitive   = true
}

output "acr_login_server" {
  description = "ACR login server (only if enable_acr=true)"
  value       = var.enable_acr ? azurerm_container_registry.acr[0].login_server : "ACR not enabled"
}

output "acr_name" {
  description = "ACR name (only if enable_acr=true)"
  value       = var.enable_acr ? azurerm_container_registry.acr[0].name : "ACR not enabled"
}

output "deployment_info" {
  description = "Quick reference for accessing the deployment"
  value = <<-EOT

    ========================================
    Deployment Summary
    ========================================

    VM Public IP: ${azurerm_public_ip.main.ip_address}

    SSH Command:
      ssh ${var.admin_username}@${azurerm_public_ip.main.ip_address}

    Web UIs:
      - Nomad:    http://${azurerm_public_ip.main.ip_address}:4646
      - Consul:   http://${azurerm_public_ip.main.ip_address}:8500
      - Vault:    http://${azurerm_public_ip.main.ip_address}:8200
      - Fabio:    http://${azurerm_public_ip.main.ip_address}:9998

    MySQL (Docker):
      Host:     ${azurerm_public_ip.main.ip_address}
      Port:     3306
      Database: appdb
      User:     ${var.mysql_user}
      Password: (use var.mysql_password from tfvars)

    Application Routing (Fabio):
      http://${azurerm_public_ip.main.ip_address}:9999

    To deploy Nomad jobs, SSH into the VM and use:
      nomad job run <jobfile.nomad>

    ========================================
  EOT
}
