locals {
  vnet_name          = "${var.prefix}-vnet"
  private_dns_vnet_link  = "vnet-private-dns-link"
}

resource azurerm_virtual_network "vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = local.vnet_name
  address_space       = ["172.22.0.0/16"]
  location            = var.location
  tags                = var.tags
}

resource azurerm_subnet "subnet_1" {
  name                 = "${var.prefix}-appgwy-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix     = "172.22.6.0/24"
}

resource azurerm_subnet "subnet_2" {
  name                 = "${var.prefix}-aks-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix     = "172.22.32.0/20"
}

resource azurerm_subnet "subnet_3" {
  name                 = "${var.prefix}-apim-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix     = "172.22.48.0/24"
}

resource azurerm_subnet "subnet_4" {
  name                 = "${var.prefix}-db-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix     = "172.22.49.0/24"
  enforce_private_link_endpoint_network_policies = true
}

resource azurerm_subnet "subnet_5" {
  name                 = "${var.prefix}-mgmt-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefix     = "172.22.50.0/24"
}
