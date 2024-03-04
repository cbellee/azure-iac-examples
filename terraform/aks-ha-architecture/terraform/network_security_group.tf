resource azurerm_network_security_group "region1_bastion_subnet_nsg" {
  name                = "bastion-rule"
  location            = azurerm_resource_group.region1_rg.location
  resource_group_name = azurerm_resource_group.region1_rg.name

  security_rule {
    name                       = "allow-bastion-subnet-internet-inbound-ssh"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = azurerm_subnet.region1_hub_subnet_3.address_prefixes[0]
  }

  tags = var.tags
}

resource azurerm_subnet_network_security_group_association "region1_bastion_subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.region1_hub_subnet_3.id
  network_security_group_id = azurerm_network_security_group.region1_bastion_subnet_nsg.id
}

resource azurerm_network_security_group "region2_bastion_subnet_nsg" {
  name                = "bastion-rule"
  location            = azurerm_resource_group.region2_rg.location
  resource_group_name = azurerm_resource_group.region2_rg.name

  security_rule {
    name                       = "allow-bastion-subnet-internet-inbound-ssh"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = azurerm_subnet.region2_hub_subnet_3.address_prefixes[0]
  }

  tags = var.tags
}

resource azurerm_subnet_network_security_group_association "region2_bastion_subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.region2_hub_subnet_3.id
  network_security_group_id = azurerm_network_security_group.region2_bastion_subnet_nsg.id
}