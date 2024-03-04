resource "azurerm_postgresql_server" "azpgres" {
  name                         = "${var.prefix}-azpgres"
  location                     = azurerm_resource_group.rg.location
  resource_group_name          = azurerm_resource_group.rg.name
  administrator_login          = var.pgres_admin
  administrator_login_password = var.pgres_password

  sku_name   = "GP_Gen5_4"
  version    = "9.6"
  storage_mb = 640000

  backup_retention_days        = 7
  geo_redundant_backup_enabled = true
  auto_grow_enabled            = true

  public_network_access_enabled    = false
  ssl_enforcement_enabled          = true
  ssl_minimal_tls_version_enforced = "TLS1_2"
  tags                             = var.tags
}

resource "azurerm_postgresql_database" "pgres_db_1" {
  name                = "exampledb"
  resource_group_name = azurerm_resource_group.rg.name
  server_name         = azurerm_postgresql_server.azpgres.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

resource "azurerm_private_endpoint" "azpgres_plink" {
  name                = "${var.prefix}-postgres-endpoint"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.subnet_4.id

  private_service_connection {
    name                           = "postgres-private-link"
    is_manual_connection           = "false"
    private_connection_resource_id = azurerm_postgresql_server.azpgres.id
    subresource_names              = ["postgresqlServer"]
  }
}

resource "azurerm_private_dns_zone" "azpgres_plink_dns_private_zone" {
  name                = "postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_private_dns_a_record" "azpgres_private_endpoint_a_record" {
  name                = azurerm_postgresql_server.azpgres.name
  zone_name           = azurerm_private_dns_zone.azpgres_plink_dns_private_zone.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.azpgres_plink.private_service_connection[0].private_ip_address]
}

resource "azurerm_private_dns_zone_virtual_network_link" "azpgres_zone_to_vnet_link" {
  name                  = "azpgres-vnet-plink"
  resource_group_name   = azurerm_private_endpoint.azpgres_plink.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.azpgres_plink_dns_private_zone.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}
