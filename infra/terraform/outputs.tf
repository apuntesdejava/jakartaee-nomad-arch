# outputs.tf — agrega el ACR
output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "push_commands" {
  value = <<-EOT
    # Ejecuta esto en local después del terraform apply:
    az acr login --name ${azurerm_container_registry.acr.name}

    docker tag quarkus/clients-hc-example-jvm:0.0.1 \
      ${azurerm_container_registry.acr.login_server}/clients-hc-example-jvm:0.0.1
    docker push ${azurerm_container_registry.acr.login_server}/clients-hc-example-jvm:0.0.1

    docker tag payara/sales-hc-example:0.0.1 \
      ${azurerm_container_registry.acr.login_server}/sales-hc-example:0.0.1
    docker push ${azurerm_container_registry.acr.login_server}/sales-hc-example:0.0.1
  EOT
}