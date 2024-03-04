resource azurerm_network_security_group "appgwy_subnet_nsg" {
  name                = "${var.prefix}-appgwy-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "in-appgwy-mgmt-65200-65535"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "TCP"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

resource azurerm_subnet_network_security_group_association "appgwy_subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet_1.id
  network_security_group_id = azurerm_network_security_group.appgwy_subnet_nsg.id
}

resource azurerm_network_security_group "aks_subnet_nsg" {
  name                = "${var.prefix}-aks-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  /*   security_rule {
    name                       = ""
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = ""
  } */

  tags = var.tags
}

resource azurerm_subnet_network_security_group_association "aks_subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet_2.id
  network_security_group_id = azurerm_network_security_group.aks_subnet_nsg.id
}

resource azurerm_network_security_group "apim_subnet_nsg" {
  name                = "${var.prefix}-apim-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow_in_from_appgwy_subnet_80_443"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = [80, 443]
    source_address_prefix      = azurerm_subnet.subnet_1.address_prefix # app gateway
    destination_address_prefix = azurerm_subnet.subnet_3.address_prefix # api management
  }

  security_rule {
    name                       = "allow_mgmt_in_from_apim_tag"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = [3443]
    source_address_prefix      = "ApiManagement"
    destination_address_prefix = "VirtualNetwork"
  }

  tags = var.tags
}

resource azurerm_subnet_network_security_group_association "apim_subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet_3.id
  network_security_group_id = azurerm_network_security_group.apim_subnet_nsg.id
}

resource azurerm_network_security_group "db_subnet_nsg" {
  name                = "${var.prefix}-db-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  /*   security_rule {
    name                       = ""
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = ""
  } */

  tags = var.tags
}

/* resource azurerm_subnet_network_security_group_association "db_subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet_4.id
  network_security_group_id = azurerm_network_security_group.db_subnet_nsg.id
} */

resource azurerm_network_security_group "mgmt_subnet_nsg" {
  name                = "${var.prefix}-mgmt-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-internet-inbound-ssh"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "VirtualNetwork"
  }
  tags = var.tags
}

resource azurerm_subnet_network_security_group_association "mgmt_subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet_5.id
  network_security_group_id = azurerm_network_security_group.mgmt_subnet_nsg.id
}
