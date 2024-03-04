locals {
  ws_name = "${var.prefix}-${random_id.laws.hex}-ws"
}

resource azurerm_log_analytics_workspace "workspace" {
  name                = local.ws_name
  location            = azurerm_resource_group.rg["mgmt-rg"].location
  resource_group_name = azurerm_resource_group.rg["mgmt-rg"].name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags = var.tags
}
