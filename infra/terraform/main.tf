terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}

locals {
  name_prefix = "jakartaee-nomad"
  mysql_fqdn = var.manage_mysql ? (
    azurerm_mysql_flexible_server.mysql[0].fqdn
    ) : (
    data.azurerm_mysql_flexible_server.mysql[0].fqdn
  )
}

moved {
  from = azurerm_mysql_flexible_server.mysql
  to   = azurerm_mysql_flexible_server.mysql[0]
}

moved {
  from = azurerm_mysql_flexible_database.db
  to   = azurerm_mysql_flexible_database.db[0]
}

moved {
  from = azurerm_mysql_flexible_server_firewall_rule.allow_control
  to   = azurerm_mysql_flexible_server_firewall_rule.allow_control[0]
}

moved {
  from = azurerm_mysql_flexible_server_firewall_rule.allow_nat
  to   = azurerm_mysql_flexible_server_firewall_rule.allow_nat[0]
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${local.name_prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "nomad-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "control_pip" {
  name                = "${local.name_prefix}-control-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "gateway_pip" {
  name                = "${local.name_prefix}-gateway-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "nat_pip" {
  name                = "${local.name_prefix}-nat-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat" {
  name                = "${local.name_prefix}-nat"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "nat" {
  nat_gateway_id       = azurerm_nat_gateway.nat.id
  public_ip_address_id = azurerm_public_ip.nat_pip.id
}

resource "azurerm_subnet_nat_gateway_association" "subnet" {
  subnet_id      = azurerm_subnet.subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat.id
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${local.name_prefix}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "AllowVnetInternal"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.my_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "NomadUI"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "4646"
    source_address_prefix      = var.my_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "ConsulUI"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8500"
    source_address_prefix      = var.my_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Gateway"
    priority                   = 1004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "FabioUI"
    priority                   = 1005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9998"
    source_address_prefix      = var.my_ip
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "VaultUI"
    priority                   = 1006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8200"
    source_address_prefix      = var.my_ip
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "subnet" {
  subnet_id                 = azurerm_subnet.subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "azurerm_lb" "gateway" {
  name                = "${local.name_prefix}-gateway-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "gateway-public"
    public_ip_address_id = azurerm_public_ip.gateway_pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "gateway" {
  name            = "nomad-workers"
  loadbalancer_id = azurerm_lb.gateway.id
}

resource "azurerm_lb_probe" "gateway" {
  name            = "fabio-http"
  loadbalancer_id = azurerm_lb.gateway.id
  protocol        = "Tcp"
  port            = 8000
}

resource "azurerm_lb_rule" "gateway" {
  name                           = "gateway-8000"
  loadbalancer_id                = azurerm_lb.gateway.id
  protocol                       = "Tcp"
  frontend_port                  = 8000
  backend_port                   = 8000
  frontend_ip_configuration_name = "gateway-public"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.gateway.id]
  probe_id                       = azurerm_lb_probe.gateway.id
}

resource "azurerm_network_interface" "control" {
  name                = "${local.name_prefix}-control-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.10"
    public_ip_address_id          = azurerm_public_ip.control_pip.id
  }
}

data "azurerm_mysql_flexible_server" "mysql" {
  count               = var.manage_mysql ? 0 : 1
  name                = var.mysql_server_name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_mysql_flexible_server" "mysql" {
  count                  = var.manage_mysql ? 1 : 0
  name                   = var.mysql_server_name
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  administrator_login    = var.mysql_user
  administrator_password = var.mysql_password
  sku_name               = var.mysql_sku
  version                = "8.4"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [version]
  }
}

resource "azurerm_mysql_flexible_database" "db" {
  count               = var.manage_mysql ? 1 : 0
  name                = "appdb"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql[0].name
  charset             = "utf8"
  collation           = "utf8_general_ci"

  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_mysql_flexible_server_configuration" "require_secure_transport" {
  count               = var.manage_mysql ? 1 : 0
  name                = "require_secure_transport"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql[0].name
  value               = "OFF"
}

resource "azurerm_mysql_flexible_server_firewall_rule" "allow_control" {
  count               = var.manage_mysql ? 1 : 0
  name                = "allow-control-plane"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql[0].name
  start_ip_address    = azurerm_public_ip.control_pip.ip_address
  end_ip_address      = azurerm_public_ip.control_pip.ip_address
}

resource "azurerm_mysql_flexible_server_firewall_rule" "allow_nat" {
  count               = var.manage_mysql ? 1 : 0
  name                = "allow-nomad-workers"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_mysql_flexible_server.mysql[0].name
  start_ip_address    = azurerm_public_ip.nat_pip.ip_address
  end_ip_address      = azurerm_public_ip.nat_pip.ip_address
}

resource "azurerm_linux_virtual_machine" "control" {
  name                  = "${local.name_prefix}-control"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.control.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(templatefile("${path.module}/cloud-init-control.yaml", {
    admin_username    = var.admin_username
    consul_version    = var.consul_version
    nomad_version     = var.nomad_version
    vault_version     = var.vault_version
    mysql_user        = var.mysql_user
    mysql_password    = var.mysql_password
    mysql_host        = local.mysql_fqdn
    api_gateway_nomad = base64encode(file("${path.module}/../nomad/api-gateway.nomad"))
    clients_nomad     = base64encode(file("${path.module}/../nomad/clients.nomad"))
    products_nomad    = base64encode(file("${path.module}/../nomad/products.nomad"))
    sales_nomad       = base64encode(file("${path.module}/../nomad/sales.nomad"))
  }))

  depends_on = [
    azurerm_mysql_flexible_database.db,
    azurerm_mysql_flexible_server_configuration.require_secure_transport,
    azurerm_mysql_flexible_server_firewall_rule.allow_control,
    azurerm_mysql_flexible_server_firewall_rule.allow_nat,
    data.azurerm_mysql_flexible_server.mysql
  ]
}

resource "azurerm_linux_virtual_machine_scale_set" "workers" {
  name                = "${local.name_prefix}-workers"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = var.worker_vm_size
  instances           = var.worker_count
  admin_username      = var.admin_username

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.admin_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  network_interface {
    name    = "worker-nic"
    primary = true

    ip_configuration {
      name                                   = "internal"
      primary                                = true
      subnet_id                              = azurerm_subnet.subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.gateway.id]
    }
  }

  custom_data = base64encode(templatefile("${path.module}/cloud-init-worker.yaml", {
    admin_username     = var.admin_username
    consul_version     = var.consul_version
    nomad_version      = var.nomad_version
    control_private_ip = azurerm_network_interface.control.private_ip_address
  }))

  depends_on = [
    azurerm_linux_virtual_machine.control,
    azurerm_subnet_nat_gateway_association.subnet
  ]
}

output "control_public_ip" {
  value = azurerm_public_ip.control_pip.ip_address
}

output "gateway_public_ip" {
  value = azurerm_public_ip.gateway_pip.ip_address
}

output "mysql_host" {
  value = local.mysql_fqdn
}

output "ssh_control" {
  value = "ssh ${var.admin_username}@${azurerm_public_ip.control_pip.ip_address}"
}
