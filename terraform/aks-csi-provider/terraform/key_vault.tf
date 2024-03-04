locals {
  kv_name = "${var.prefix}-kv"
}

resource azurerm_key_vault "kv" {
  name                        = local.kv_name
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  soft_delete_enabled         = true
  purge_protection_enabled    = false

  sku_name = "standard"

  access_policy {
    tenant_id = var.tenant_id
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
    tenant_id = var.tenant_id
    object_id = azuread_user.csi-provider-demo-key-vault-user.id

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
    tenant_id = var.tenant_id
    object_id = var.azure-service-connection-objectid

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

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }

  tags = var.tags
}



resource azurerm_key_vault_secret "kv_secret" {
  name         = var.secret_name
  value        = var.secret_value
  key_vault_id = azurerm_key_vault.kv.id

  tags = var.tags
}
