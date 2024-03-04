resource "azurerm_sql_server" "azsql" {
  name                         = "${var.prefix}-azsql"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.azsql_admin
  administrator_login_password = var.azsql_password

  extended_auditing_policy {
    storage_endpoint                        = azurerm_storage_account.azsql_stor.primary_blob_endpoint
    storage_account_access_key              = azurerm_storage_account.azsql_stor.primary_access_key
    storage_account_access_key_is_secondary = true
    retention_in_days                       = 6
  }

  tags = var.tags
}

resource "azurerm_storage_account" "azsql_stor" {
  name                     = lower("azsqlstr${random_string.random.result}")
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = var.tags
}

resource "azurerm_private_endpoint" "azsql_plink" {
  name                = "${var.prefix}-sql-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet_4.id

  private_service_connection {
    name                           = "sqlprivatelink"
    is_manual_connection           = "false"
    private_connection_resource_id = azurerm_sql_server.azsql.id
    subresource_names              = ["sqlServer"]
  }
}

data "azurerm_private_dns_zone" "azsql_plink_dns_private_zone" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_a_record" "azsql_private_endpoint_a_record" {
  name                = azurerm_sql_server.azsql.name
  zone_name           = data.azurerm_private_dns_zone.azsql_plink_dns_private_zone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.azsql_plink.private_service_connection[0].private_ip_address]
}

resource "azurerm_private_dns_zone_virtual_network_link" "azsql_zone_to_vnet_link" {
  name                  = "azsql-vnet-plink"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = data.azurerm_private_dns_zone.azsql_plink_dns_private_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
} 
