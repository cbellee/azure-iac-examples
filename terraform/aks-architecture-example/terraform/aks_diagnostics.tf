
resource "azurerm_monitor_diagnostic_setting" "prod_aks_diagnostics" {
  name                       = "${var.prefix}-prod-aks-diagnostics"
  target_resource_id         = azurerm_kubernetes_cluster.prod_cluster.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id

  dynamic "log" {
      for_each = var.aks_diagnostics_logs_map.log
      content {
        category = log.value[0]
        enabled  = log.value[1]
        retention_policy {
          enabled = log.value[2]
          days    = log.value[3]
        }
     }
  }

  dynamic "metric" {
    for_each = var.aks_diagnostics_logs_map.metric
    content {
      category = metric.value[0]
      enabled  = metric.value[1]
      retention_policy {
        enabled = metric.value[2]
        days    = metric.value[3]
      }
    }
  }
}

resource "azurerm_monitor_diagnostic_setting" "nonprod_aks_diagnostics" {
  name                       = "${var.prefix}-nonprod-aks-diagnostics"
  target_resource_id         = azurerm_kubernetes_cluster.nonprod_cluster.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id

  dynamic "log" {
      for_each = var.aks_diagnostics_logs_map.log
      content {
        category = log.value[0]
        enabled  = log.value[1]
        retention_policy {
          enabled = log.value[2]
          days    = log.value[3]
        }
      }
    }

  dynamic "metric" {
    for_each = var.aks_diagnostics_logs_map.metric
    content {
      category = metric.value[0]
      enabled  = metric.value[1]
      retention_policy {
        enabled = metric.value[2]
        days    = metric.value[3]
      }
    }
  }
}
