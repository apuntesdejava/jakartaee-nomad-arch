# terraform/main.tf — agrega esto antes de la VM

# Azure Container Registry (SKU Basic: ~$5/mes)
resource "azurerm_container_registry" "acr" {
  name                = "${replace(var.prefix, "-", "")}acr"  # sin guiones
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true   # simplifica el pull desde la VM
}

# Darle permisos a la VM para hacer pull del ACR
resource "azurerm_role_assignment" "vm_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_linux_virtual_machine.main.identity[0].principal_id
}