resource "azurerm_monitor_diagnostic_setting" "az_firewall_diagnostics" {
  name                       = "${var.prefix}-fw-diagnostics"
  target_resource_id         = azurerm_firewall.az_firewall.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id

/*   enabled_log {
    category = "AzureFirewallApplicationRule"
  }
  enabled_log {
    category = "AzureFirewallNetworkRule"
  } */
  metric {
    category = "AllMetrics"
  }
}
