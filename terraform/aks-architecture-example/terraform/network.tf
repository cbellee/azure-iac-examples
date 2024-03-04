locals {
  private_dns_vnet_link   = "hub-vnet-private-dns-link"
}

# vnets
resource azurerm_virtual_network "vnet" {
  for_each = { 
    for vnet in var.vnets : vnet.name => vnet 
  }

  resource_group_name = azurerm_resource_group.rg["network-rg"].name
  name                = each.value.name
  address_space       = each.value.address_space
  location            = var.location
  tags                = var.tags

  dynamic subnet {
    for_each = each.value.subnets

      content {
        name           = subnet.key
        address_prefix = cidrsubnet(each.value.address_space[0], 8, subnet.value.subnet_increment)
      }
   }
}

resource azurerm_subnet_route_table_association "prod_spoke_subnet_1_route_table_assoc" {
  subnet_id       = element(tolist(azurerm_virtual_network.vnet["prod-spoke-vnet"].subnet),0).id
  route_table_id = azurerm_route_table.aks_firewall_route_table.id

  timeouts {
    create = "2h"
    delete = "2h"
  }
}

resource azurerm_subnet_route_table_association "prod_spoke_subnet_2_route_table_assoc" {
  subnet_id      = element(tolist(azurerm_virtual_network.vnet["prod-spoke-vnet"].subnet),1).id
  route_table_id = azurerm_route_table.aks_firewall_route_table.id

  timeouts {
    create = "2h"
    delete = "2h"
  }
}

resource azurerm_subnet_route_table_association "prod_spoke_subnet_3_route_table_assoc" {
  subnet_id      = element(tolist(azurerm_virtual_network.vnet["prod-spoke-vnet"].subnet),2).id
  route_table_id = azurerm_route_table.aks_firewall_route_table.id

  timeouts {
    create = "2h"
    delete = "2h"
  }
}

resource azurerm_subnet_route_table_association "nonprod_spoke_subnet_1_route_table_assoc" {
  subnet_id      = element(tolist(azurerm_virtual_network.vnet["nonprod-spoke-vnet"].subnet),0).id
  route_table_id = azurerm_route_table.aks_firewall_route_table.id

  timeouts {
    create = "2h"
    delete = "2h"
  }
}

resource azurerm_subnet_route_table_association "nonprod_spoke_subnet_2_route_table_assoc" {
  subnet_id      = element(tolist(azurerm_virtual_network.vnet["nonprod-spoke-vnet"].subnet),1).id
  route_table_id = azurerm_route_table.aks_firewall_route_table.id

  timeouts {
    create = "2h"
    delete = "2h"
  }
}

resource azurerm_subnet_route_table_association "nonprod_spoke_subnet_3_route_table_assoc" {
  subnet_id      = element(tolist(azurerm_virtual_network.vnet["nonprod-spoke-vnet"].subnet),2).id
  route_table_id = azurerm_route_table.aks_firewall_route_table.id

  timeouts {
    create = "2h"
    delete = "2h"
  }
}

resource azurerm_virtual_network_peering "hub_to_prod_spoke_peer" {
  name                         = "hub_to_prod_spoke_peer"
  resource_group_name          = azurerm_resource_group.rg["network-rg"].name
  virtual_network_name         = azurerm_virtual_network.vnet["hub-vnet"].name
  remote_virtual_network_id    = azurerm_virtual_network.vnet["prod-spoke-vnet"].id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = false
}

resource azurerm_virtual_network_peering "hub_to_nonprod_spoke_peer" {
  name                         = "hub_to_nonprod_spoke_peer"
  resource_group_name          = azurerm_resource_group.rg["network-rg"].name
  virtual_network_name         = azurerm_virtual_network.vnet["hub-vnet"].name
  remote_virtual_network_id    = azurerm_virtual_network.vnet["nonprod-spoke-vnet"].id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = false
}

resource azurerm_virtual_network_peering "prod_spoke_to_hub_peer" {
  name                         = "prod_spoke_to_hub_peer"
  resource_group_name          = azurerm_resource_group.rg["network-rg"].name
  virtual_network_name         = azurerm_virtual_network.vnet["prod-spoke-vnet"].name
  remote_virtual_network_id    =  azurerm_virtual_network.vnet["hub-vnet"].id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = false
}

resource azurerm_virtual_network_peering "nonprod_spoke_to_hub_peer" {
  name                         = "nonprod_spoke_to_hub_peer"
  resource_group_name          = azurerm_resource_group.rg["network-rg"].name
  virtual_network_name         = azurerm_virtual_network.vnet["nonprod-spoke-vnet"].name
  remote_virtual_network_id    =  azurerm_virtual_network.vnet["hub-vnet"].id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = false
}
