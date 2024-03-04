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

resource azurerm_subnet "hub_subnet_2" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource azurerm_subnet "hub_subnet_3" {
  name                 = "BastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource azurerm_subnet "hub_subnet_4" {
  name                 = "AdoVmssSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub_vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

resource azurerm_subnet_route_table_association "hub_subnet_3_route_table" {
  subnet_id      = azurerm_subnet.hub_subnet_3.id
  route_table_id = azurerm_route_table.firewall_route_table.id

  timeouts {
    create = "2h"
    delete = "2h"
  }
}

resource azurerm_subnet "spoke_subnet_1" {
  name                 = "AKSNodesSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke_vnet.name
  address_prefixes     = ["10.1.0.0/24"]
}

resource azurerm_subnet_route_table_association "spoke_subnet_1_route_table" {
  subnet_id      = azurerm_subnet.spoke_subnet_1.id
  route_table_id = azurerm_route_table.aks_firewall_route_table.id

  timeouts {
    create = "2h"
    delete = "2h"
  }
}

resource azurerm_virtual_network_peering "hub_spoke_peer" {
  name                         = local.hub_to_spoke_peer_name
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.hub_vnet.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke_vnet.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = true
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

/* resource "azurerm_private_dns_zone_virtual_network_link" "aks_private_dns_zone" {
  name                  = "hub-vnet-link"
  resource_group_name   = azurerm_kubernetes_cluster.aks_cluster.node_resource_group
  private_dns_zone_name = join(".", element(split(".", azurerm_kubernetes_cluster.aks_cluster.private_fqdn), 1), element(split(".", azurerm_kubernetes_cluster.aks_cluster.private_fqdn), 2), element(split(".", azurerm_kubernetes_cluster.aks_cluster.private_fqdn), 3), element(split(".", azurerm_kubernetes_cluster.aks_cluster.private_fqdn), 4), element(split(".", azurerm_kubernetes_cluster.aks_cluster.private_fqdn), 5))
  virtual_network_id    = azurerm_virtual_network.hub_vnet.id
} */
