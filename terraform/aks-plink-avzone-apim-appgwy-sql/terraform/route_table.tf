resource azurerm_route_table "aks_route_table" {
  name                          = "${var.prefix}-aks-rt"
  location                      = azurerm_resource_group.rg.location
  resource_group_name           = azurerm_resource_group.rg.name
  disable_bgp_route_propagation = false

  route {
    name                   = "aks_internet_route"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "Internet"
  }

  tags = var.tags
}
