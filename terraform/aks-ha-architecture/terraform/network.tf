locals {
  region1_hub_vnet_name   = "${var.prefix}-${var.region1.locationShortName}-hub-vnet"
  region2_hub_vnet_name   = "${var.prefix}-${var.region2.locationShortName}-hub-vnet"
  region1_spoke_vnet_name = "${var.prefix}-${var.region1.locationShortName}-spoke-vnet"
  region2_spoke_vnet_name = "${var.prefix}-${var.region2.locationShortName}-spoke-vnet"
  hub_to_spoke_peer_name  = "hub-to-spoke"
  spoke_to_hub_peer_name  = "hub-to-spoke"
}

# vnets
resource azurerm_virtual_network "region1_hub_vnet" {
  resource_group_name = azurerm_resource_group.region1_rg.name
  name                = local.region1_hub_vnet_name
  address_space       = [var.region1.hubVnet.prefix]
  location            = var.region1.location
  tags                = var.tags
}

resource azurerm_virtual_network "region1_spoke_vnet" {
  resource_group_name = azurerm_resource_group.region1_rg.name
  name                = local.region1_spoke_vnet_name
  address_space       = [var.region1.spokeVnet.prefix]
  location            = var.region1.location
  tags                = var.tags
}

resource azurerm_subnet "region1_hub_subnet_1" {
  name                 = var.region1.hubVnet.subnets[0].name
  resource_group_name  = azurerm_resource_group.region1_rg.name
  virtual_network_name = azurerm_virtual_network.region1_hub_vnet.name
  address_prefixes     = [var.region1.hubVnet.subnets[0].address]
}

resource azurerm_subnet "region1_hub_subnet_2" {
  name                 = var.region1.hubVnet.subnets[1].name
  resource_group_name  = azurerm_resource_group.region1_rg.name
  virtual_network_name = azurerm_virtual_network.region1_hub_vnet.name
  address_prefixes     = [var.region1.hubVnet.subnets[1].address]
}

resource azurerm_subnet "region1_hub_subnet_3" {
  name                 = var.region1.hubVnet.subnets[2].name
  resource_group_name  = azurerm_resource_group.region1_rg.name
  virtual_network_name = azurerm_virtual_network.region1_hub_vnet.name
  address_prefixes     = [var.region1.hubVnet.subnets[2].address]
}

resource azurerm_subnet_route_table_association "region1_hub_subnet_2_route_table" {
  subnet_id      = azurerm_subnet.region1_hub_subnet_2.id
  route_table_id = azurerm_route_table.region1_firewall_route_table.id
}

resource azurerm_subnet_route_table_association "region1_hub_subnet_3_route_table" {
  subnet_id      = azurerm_subnet.region1_hub_subnet_3.id
  route_table_id = azurerm_route_table.region1_firewall_route_table.id
}

resource azurerm_subnet "region1_spoke_subnet_1" {
  name                 = var.region1.spokeVnet.subnets[0].name
  resource_group_name  = azurerm_resource_group.region1_rg.name
  virtual_network_name = azurerm_virtual_network.region1_spoke_vnet.name
  address_prefixes     = [var.region1.spokeVnet.subnets[0].address]
}

resource azurerm_subnet "region1_spoke_subnet_2" {
  name                 = var.region1.spokeVnet.subnets[1].name
  resource_group_name  = azurerm_resource_group.region1_rg.name
  virtual_network_name = azurerm_virtual_network.region1_spoke_vnet.name
  address_prefixes     = [var.region1.spokeVnet.subnets[1].address]
}

resource azurerm_subnet_route_table_association "region1_spoke_subnet_1_route_table" {
  subnet_id      = azurerm_subnet.region1_spoke_subnet_1.id
  route_table_id = azurerm_route_table.region1_firewall_route_table.id
}

resource azurerm_subnet_route_table_association "region1_spoke_subnet_2_route_table" {
  subnet_id      = azurerm_subnet.region1_spoke_subnet_2.id
  route_table_id = azurerm_route_table.region1_firewall_route_table.id
}

resource azurerm_virtual_network "region2_hub_vnet" {
  resource_group_name = azurerm_resource_group.region2_rg.name
  name                = local.region2_hub_vnet_name
  address_space       = [var.region2.hubVnet.prefix]
  location            = var.region2.location
  tags                = var.tags
}

resource azurerm_subnet "region2_hub_subnet_1" {
  name                 = var.region2.hubVnet.subnets[0].name
  resource_group_name  = azurerm_resource_group.region2_rg.name
  virtual_network_name = azurerm_virtual_network.region2_hub_vnet.name
  address_prefixes     = [var.region2.hubVnet.subnets[0].address]
}

resource azurerm_subnet "region2_hub_subnet_2" {
  name                 = var.region2.hubVnet.subnets[1].name
  resource_group_name  = azurerm_resource_group.region2_rg.name
  virtual_network_name = azurerm_virtual_network.region2_hub_vnet.name
  address_prefixes     = [var.region2.hubVnet.subnets[1].address]
}

resource azurerm_subnet "region2_hub_subnet_3" {
  name                 = var.region2.hubVnet.subnets[2].name
  resource_group_name  = azurerm_resource_group.region2_rg.name
  virtual_network_name = azurerm_virtual_network.region2_hub_vnet.name
  address_prefixes     = [var.region2.hubVnet.subnets[2].address]
}

resource azurerm_subnet_route_table_association "region_2_hub_subnet_2_route_table" {
  subnet_id      = azurerm_subnet.region2_hub_subnet_2.id
  route_table_id = azurerm_route_table.region2_firewall_route_table.id
}

resource azurerm_subnet_route_table_association "region_2_hub_subnet_3_route_table" {
  subnet_id      = azurerm_subnet.region2_hub_subnet_3.id
  route_table_id = azurerm_route_table.region2_firewall_route_table.id
}

resource azurerm_virtual_network "region2_spoke_vnet" {
  resource_group_name = azurerm_resource_group.region2_rg.name
  name                = local.region2_spoke_vnet_name
  address_space       = [var.region2.spokeVnet.prefix]
  location            = var.region2.location
  tags                = var.tags
}

resource azurerm_subnet "region2_spoke_subnet_1" {
  name                 = var.region2.spokeVnet.subnets[0].name
  resource_group_name  = azurerm_resource_group.region2_rg.name
  virtual_network_name = azurerm_virtual_network.region2_spoke_vnet.name
  address_prefixes     = [var.region2.spokeVnet.subnets[0].address]
}

resource azurerm_subnet "region2_spoke_subnet_2" {
  name                 = var.region2.spokeVnet.subnets[1].name
  resource_group_name  = azurerm_resource_group.region2_rg.name
  virtual_network_name = azurerm_virtual_network.region2_spoke_vnet.name
  address_prefixes     = [var.region2.spokeVnet.subnets[1].address]
}

resource azurerm_subnet_route_table_association "region_2_spoke_subnet_1_route_table" {
  subnet_id      = azurerm_subnet.region2_spoke_subnet_1.id
  route_table_id = azurerm_route_table.region2_firewall_route_table.id
}

resource azurerm_subnet_route_table_association "region_2_spoke_subnet_2_route_table" {
  subnet_id      = azurerm_subnet.region2_spoke_subnet_2.id
  route_table_id = azurerm_route_table.region2_firewall_route_table.id
}

# peering
resource azurerm_virtual_network_peering "region1_hub_spoke_peer" {
  name                         = local.hub_to_spoke_peer_name
  resource_group_name          = azurerm_resource_group.region1_rg.name
  virtual_network_name         = azurerm_virtual_network.region1_hub_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.region1_spoke_vnet.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource azurerm_virtual_network_peering "region1_spoke_hub_peer" {
  name                         = local.spoke_to_hub_peer_name
  resource_group_name          = azurerm_resource_group.region1_rg.name
  virtual_network_name         = azurerm_virtual_network.region1_spoke_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.region1_hub_vnet.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource azurerm_virtual_network_peering "region2_hub_spoke_peer" {
  name                         = local.hub_to_spoke_peer_name
  resource_group_name          = azurerm_resource_group.region2_rg.name
  virtual_network_name         = azurerm_virtual_network.region2_hub_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.region2_spoke_vnet.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource azurerm_virtual_network_peering "region2_spoke_hub_peer" {
  name                         = local.spoke_to_hub_peer_name
  resource_group_name          = azurerm_resource_group.region2_rg.name
  virtual_network_name         = azurerm_virtual_network.region2_spoke_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.region2_hub_vnet.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

