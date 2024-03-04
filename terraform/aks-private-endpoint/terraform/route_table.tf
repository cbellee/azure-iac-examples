locals {
  rt_name = "${var.prefix}-fw-rt"
  aks_rt_name = "${var.prefix}-aks-fw-rt"
}

resource azurerm_route_table "firewall_route_table" {
  name                          = local.rt_name
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  disable_bgp_route_propagation = false

  route {
    name                   = "default_hub_fw_route"
    address_prefix         = azurerm_virtual_network.hub_vnet.address_space[0]
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.az_firewall.ip_configuration[0].private_ip_address
  }

  tags = var.tags
}

resource azurerm_route_table "aks_firewall_route_table" {
  name                          = local.aks_rt_name
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  disable_bgp_route_propagation = false

  route {
    name                   = "default_spoke_fw_route"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.az_firewall.ip_configuration[0].private_ip_address
  }

  tags = var.tags
}

