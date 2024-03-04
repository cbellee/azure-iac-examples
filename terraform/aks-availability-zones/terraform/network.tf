locals {
  hub_vnet_name          = "${var.prefix}-hub-vnet"
  spoke_vnet_name        = "${var.prefix}-spoke-vnet"
  hub_to_spoke_peer_name = "hub-to-spoke"
  spoke_to_hub_peer_name = "spoke-to-hub"
  private_dns_vnet_link  = "hub-vnet-private-dns-link"
}

# vnets
resource azurerm_virtual_network "hub_vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = local.hub_vnet_name
  address_space       = ["10.0.0.0/16"]
  location            = var.location
  tags                = var.tags
}

resource azurerm_virtual_network "spoke_vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = local.spoke_vnet_name
  address_space       = ["10.1.0.0/16"]
  location            = var.location
  tags                = var.tags
}

resource azurerm_subnet "hub_subnet_1" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource azurerm_subnet "spoke_subnet_1" {
  name                 = "AKSNodePoolSubnet1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name
  address_prefixes     = ["10.1.0.0/24"]
}

resource azurerm_subnet "spoke_subnet_2" {
  name                 = "AKSNodePoolSubnet2"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource azurerm_virtual_network_peering "hub_spoke_peer" {
  name                         = local.hub_to_spoke_peer_name
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke_vnet.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = false
}

resource azurerm_virtual_network_peering "spoke_hub_peer" {
  name                         = local.spoke_to_hub_peer_name
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.spoke_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.hub_vnet.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  use_remote_gateways          = false
}
