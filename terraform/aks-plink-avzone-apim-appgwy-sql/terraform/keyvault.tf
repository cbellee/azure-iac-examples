resource azurerm_key_vault "kv" {
  name                        = lower("${var.prefix}-kv-${random_string.random.result}")
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_enabled         = true
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_kubernetes_cluster.aks_cluster.identity[0].principal_id

    key_permissions = [
      "get",
    ]

    secret_permissions = [
      "get",
    ]

    storage_permissions = [
      "get",
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = var.kv_access_policy_user_object_id

    key_permissions = [
      "get", "create",
    ]

    secret_permissions = [
      "get", "set", "delete", "list", "purge",
    ]

    certificate_permissions = [
      "get", "create",
    ]
  }

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  tags = var.tags
}
