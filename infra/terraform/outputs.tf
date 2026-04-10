output "vm_public_ip" {
  value = azurerm_public_ip.main.ip_address
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "acr_name" {
  value = azurerm_container_registry.acr.name
}

output "mysql_host" {
  value = azurerm_mysql_flexible_server.main.fqdn
}

output "mysql_user" {
  value = azurerm_mysql_flexible_server.main.administrator_login
}

output "push_commands" {
  value = <<-EOT
    # Ejecuta esto en local después del terraform apply:
    az acr login --name ${azurerm_container_registry.acr.name}

    docker tag quarkus/clients-hc-example-jvm:0.0.1 \
      ${azurerm_container_registry.acr.login_server}/clients-hc-example-jvm:0.0.1
    docker push ${azurerm_container_registry.acr.login_server}/clients-hc-example-jvm:0.0.1

    docker tag quarkus/products-hc-example-jvm:0.0.1 \
      ${azurerm_container_registry.acr.login_server}/products-hc-example-jvm:0.0.1
    docker push ${azurerm_container_registry.acr.login_server}/products-hc-example-jvm:0.0.1

    docker tag payara/sales-hc-example:0.0.1 \
      ${azurerm_container_registry.acr.login_server}/sales-hc-example:0.0.1
    docker push ${azurerm_container_registry.acr.login_server}/sales-hc-example:0.0.1
  EOT
}
