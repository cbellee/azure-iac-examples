locals {
  region1_rt_name = "${var.prefix}-${var.region1.locationShortName}-fw-rt"
  region2_rt_name = "${var.prefix}-${var.region2.locationShortName}-fw-rt"
}

resource azurerm_route_table "region1_firewall_route_table" {
  name                          = local.region1_rt_name
  location                      = azurerm_resource_group.region1_rg.location
  resource_group_name           = azurerm_resource_group.region1_rg.name
  disable_bgp_route_propagation = false

  route {
    name                   = "default_hub_fw_route"
    address_prefix         = var.region1.hubVnet.prefix
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.region1_az_firewall.ip_configuration[0].private_ip_address
  }

  route {
    name                   = "default_spoke_fw_route"
    address_prefix         = var.region1.spokeVnet.prefix
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.region1_az_firewall.ip_configuration[0].private_ip_address
  }

  tags = var.tags
}

resource azurerm_route_table "region2_firewall_route_table" {
  name                          = local.region2_rt_name
  location                      = azurerm_resource_group.region2_rg.location
  resource_group_name           = azurerm_resource_group.region2_rg.name
  disable_bgp_route_propagation = false

  route {
    name                   = "default-hub-fw-route"
    address_prefix         = var.region2.hubVnet.prefix
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.region2_az_firewall.ip_configuration[0].private_ip_address
  }

  route {
    name                   = "default-spoke-fw-route"
    address_prefix         = var.region2.spokeVnet.prefix
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.region2_az_firewall.ip_configuration[0].private_ip_address
  }

  tags = var.tags
}
