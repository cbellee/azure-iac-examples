locals {
  region1_ws_name = "${var.prefix}-${var.region1.locationShortName}-ws"
  region2_ws_name = "${var.prefix}-${var.region2.locationShortName}-ws"
}

resource azurerm_log_analytics_workspace "region1_workspace" {
  name                = local.region1_ws_name
  location            = azurerm_resource_group.region1_rg.location
  resource_group_name = azurerm_resource_group.region1_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags = var.tags
}

resource azurerm_log_analytics_workspace "region2_workspace" {
  name                = local.region2_ws_name
  location            = azurerm_resource_group.region2_rg.location
  resource_group_name = azurerm_resource_group.region2_rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags = var.tags
}
