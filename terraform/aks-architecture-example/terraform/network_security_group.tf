locals {
  bastion_rule_name   = "${var.prefix}-bas-rule"
}

resource azurerm_network_security_group "bastion_subnet_nsg" {
  name                = local.bastion_rule_name
  location            = azurerm_resource_group.rg["mgmt-rg"].location
  resource_group_name = azurerm_resource_group.rg["mgmt-rg"].name

  security_rule {
    name                       = "allow-bastion-subnet-internet-inbound-ssh"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "${azurerm_public_ip.az_firewall_pip.ip_address}/32"
    destination_address_prefix = element(tolist(azurerm_virtual_network.vnet["hub-vnet"].subnet),2).address_prefix
  }

  tags = var.tags
}

resource azurerm_subnet_network_security_group_association "bastion_subnet_nsg_assoc" {
  subnet_id                 = element(tolist(azurerm_virtual_network.vnet["hub-vnet"].subnet),2).id
  network_security_group_id = azurerm_network_security_group.bastion_subnet_nsg.id
}
