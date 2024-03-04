resource "azurerm_monitor_diagnostic_setting" "az_firewall_diagnostics" {
  name                       = "${var.prefix}-fw-diagnostics"
  target_resource_id         = azurerm_firewall.az_firewall.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id

  log {
    category = "AzureFirewallApplicationRule"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 7
    }
  }

  log {
    category = "AzureFirewallNetworkRule"
    enabled  = true

    retention_policy {
      enabled = true
      days    = 7
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = true
      days    = 7
    }
  }
}
