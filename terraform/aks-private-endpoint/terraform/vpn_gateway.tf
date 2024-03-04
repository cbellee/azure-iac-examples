locals {
  gwy_name               = "${var.prefix}-vpngwy"
  gwy_pip_name           = "${var.prefix}-vpngwy-pip"
  local_network_gwy_name = "${var.prefix}-local-gwy"
  local_network_gwy_cxn_name = "${var.prefix}-local-gwy-cxn"
}

resource "azurerm_public_ip" "pip" {
  name                = local.gwy_pip_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network_gateway" "vpngwy" {
  name                = local.gwy_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  type     = "Vpn"
  vpn_type = "RouteBased"

  active_active = false
  enable_bgp    = false
  sku           = "Basic"

  ip_configuration {
    name                          = "vnetGatewayConfig"
    public_ip_address_id          = azurerm_public_ip.pip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.hub_subnet_1.id
  }
}

resource "azurerm_local_network_gateway" "home-gwy" {
  name                = local.local_network_gwy_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  gateway_address     = var.on_premises_router_public_ip_address
  address_space       = [var.on_premises_router_private_cidr]
}

resource "azurerm_virtual_network_gateway_connection" "cxn" {
  name                = local.local_network_gwy_cxn_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpngwy.id
  local_network_gateway_id   = azurerm_local_network_gateway.home-gwy.id

  shared_key = random_string.random.result
}
