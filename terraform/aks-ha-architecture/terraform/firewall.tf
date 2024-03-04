locals {
  region1_fw_pip_name = "${var.prefix}-${var.region1.locationShortName}-fw-pip"
  region1_fw_name     = "${var.prefix}-${var.region1.locationShortName}-fw"
  region2_fw_pip_name = "${var.prefix}-${var.region2.locationShortName}-fw-pip"
  region2_fw_name     = "${var.prefix}-${var.region2.locationShortName}-fw"
}

resource azurerm_public_ip "region1_az_firewall_pip" {
  name                = local.region1_fw_pip_name
  location            = azurerm_resource_group.region1_rg.location
  resource_group_name = azurerm_resource_group.region1_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource azurerm_firewall "region1_az_firewall" {
  name                = local.region1_fw_name
  location            = azurerm_resource_group.region1_rg.location
  resource_group_name = azurerm_resource_group.region1_rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.region1_hub_subnet_1.id
    public_ip_address_id = azurerm_public_ip.region1_az_firewall_pip.id
  }

  tags = var.tags
}

resource azurerm_public_ip "region2_az_firewall_pip" {
  name                = local.region2_fw_pip_name
  location            = azurerm_resource_group.region2_rg.location
  resource_group_name = azurerm_resource_group.region2_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource azurerm_firewall "region2_az_firewall" {
  name                = local.region2_fw_name
  location            = azurerm_resource_group.region2_rg.location
  resource_group_name = azurerm_resource_group.region2_rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.region2_hub_subnet_1.id
    public_ip_address_id = azurerm_public_ip.region2_az_firewall_pip.id
  }

  tags = var.tags
}
