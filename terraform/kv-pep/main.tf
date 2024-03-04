locals {
  private_dns_zones = {
    azure-automation-net                        = "privatelink.azure-automation.net"
    database-windows-net                        = "privatelink.database.windows.net"
    privatelink-sql-azuresynapse-net            = "privatelink.sql.azuresynapse.net"
    privatelink-dev-azuresynapse-net            = "privatelink.dev.azuresynapse.net"
    privatelink-blob-core-windows-net           = "privatelink.blob.core.windows.net"
    privatelink-vaultcore-azure-net             = "privatelink.vaultcore.azure.net"
  }
}

data "azurerm_client_config" "example" {
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource-group-name
  location = var.location
}

resource "azurerm_private_dns_zone" "private_dns_zones" {
  for_each            = local.private_dns_zones
  name                = each.value
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.location}-vnet"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "Github_Runner_Subnet" {
  name                 = "GitHubRunnerSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.1.0/24"]
  depends_on           = [azurerm_virtual_network.vnet]
}

resource "azurerm_subnet" "Private_Endpoint_Subnet" {
  name                                           = "PrivateEndpointSubnet"
  resource_group_name                            = azurerm_resource_group.rg.name
  virtual_network_name                           = azurerm_virtual_network.vnet.name
  address_prefixes                               = ["10.1.2.0/24"]
  enforce_private_link_endpoint_network_policies = true
  depends_on                                     = [azurerm_virtual_network.vnet]
}

resource "azurerm_subnet" "Azure_Bastion_Subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.3.0/24"]
  depends_on           = [azurerm_virtual_network.vnet]
}

resource "azurerm_public_ip" "bastion" {
  name                = "bastion-ip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion" {
  name                = "bastion"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                 = "bastion-ip"
    subnet_id            = azurerm_subnet.Azure_Bastion_Subnet.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}

resource "azurerm_network_interface" "nic" {
  name                = "win-vm-01-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig"
    subnet_id                     = azurerm_subnet.Github_Runner_Subnet.id
    private_ip_address_allocation = "Dynamic"
    private_ip_address_version    = "IPv4"
  }
}

resource "azurerm_virtual_machine" "vm" {
  name                  = "win-vm-01"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  vm_size               = "Standard_DS1_v2"

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2022-datacenter-azure-edition"
    version   = "latest"
  }

  storage_os_disk {
    name              = "win-vm-01-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  os_profile {
    computer_name  = "win-vm-01"
    admin_username = var.admin_username
    admin_password = var.admin_password
  }

  os_profile_windows_config {
    provision_vm_agent = true
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "private_dns_network_links" {
  for_each              = local.private_dns_zones
  name                  = "${azurerm_virtual_network.vnet.name}-link"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = each.value
  virtual_network_id    = azurerm_virtual_network.vnet.id
  depends_on            = [azurerm_private_dns_zone.private_dns_zones]
}

resource "random_string" "random" {
  length  = 4
  special = false
}

resource "azurerm_key_vault" "main" {
  name                        = "${var.location}-${random_string.random.result}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = var.tenant_id
  enable_rbac_authorization   = true
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"
}

resource "azurerm_private_endpoint" "main" {
  name                = "${azurerm_key_vault.main.name}-pe"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  subnet_id           = azurerm_subnet.Private_Endpoint_Subnet.id
  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.private_dns_zones["privatelink-vaultcore-azure-net"].id]
  }
  private_service_connection {
    is_manual_connection           = false
    private_connection_resource_id = azurerm_key_vault.main.id
    name                           = "${azurerm_key_vault.main.name}-psc"
    subresource_names              = ["vault"]
  }
  depends_on = [azurerm_key_vault.main]
}

resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.example.object_id
}