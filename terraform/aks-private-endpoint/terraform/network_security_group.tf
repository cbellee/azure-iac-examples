locals {
  bastion_rule_name   = "${var.prefix}-bas-rule"
}

resource azurerm_network_security_group "bastion_subnet_nsg" {
  name                = local.bastion_rule_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "deny-bastion-subnet-internet-inbound-ssh"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "Internet"
    destination_address_prefix = azurerm_subnet.hub_subnet_3.address_prefixes[0]
  }

  tags = var.tags
}

resource azurerm_subnet_network_security_group_association "bastion_subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.hub_subnet_3.id
  network_security_group_id = azurerm_network_security_group.bastion_subnet_nsg.id
}
