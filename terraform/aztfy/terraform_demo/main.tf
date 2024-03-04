resource "random_id" "env" {
  keepers = {
    # Generate a new id each time we switch to a new environment id
    env_id = var.environment
  }

  byte_length = 8
}

resource "azurerm_resource_group" "rg" {
  location = var.location
  name     = var.resource_group_name
}

resource "azurerm_container_registry" "acr" {
  admin_enabled       = true
  location            = azurerm_resource_group.rg.location
  name                = "acr${var.environment}${random_id.env.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Premium"
  tags = var.tags
  depends_on = [
    azurerm_resource_group.rg,
  ]
}

resource "azurerm_virtual_network" "vnet" {
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.rg.location
  name                = "vnet-${var.environment}-${random_id.env.hex}"
  resource_group_name = azurerm_resource_group.rg.name
  tags = var.tags
  depends_on = [
    azurerm_resource_group.rg,
  ]
}

resource "azurerm_subnet" "subnet-1" {
  address_prefixes                               = var.subnet_1_cidr
  enforce_private_link_endpoint_network_policies = true
  name                                           = var.subnet_1_name
  resource_group_name                            = azurerm_resource_group.rg.name
  virtual_network_name                           = azurerm_virtual_network.vnet.name
  depends_on = [
    azurerm_virtual_network.vnet,
  ]
}

resource "azurerm_subnet" "subnet-2" {
  address_prefixes                               = var.subnet_2_cidr
  enforce_private_link_endpoint_network_policies = true
  name                                           = var.subnet_2_name
  resource_group_name                            = azurerm_resource_group.rg.name
  virtual_network_name                           = azurerm_virtual_network.vnet.name
  depends_on = [
    azurerm_virtual_network.vnet,
  ]
}

resource "azurerm_subnet" "subnet-3" {
  address_prefixes                               = var.subnet_3_cidr
  enforce_private_link_endpoint_network_policies = true
  name                                           = var.subnet_3_name
  resource_group_name                            = azurerm_resource_group.rg.name
  virtual_network_name                           = azurerm_virtual_network.vnet.name
  depends_on = [
    azurerm_virtual_network.vnet,
  ]
}

resource "azurerm_kubernetes_cluster" "aks" {
  azure_policy_enabled = true
  dns_prefix           = "aks${var.environment}"
  location             = azurerm_resource_group.rg.location
  name                 = "aks-${var.environment}-${random_id.env.hex}"
  resource_group_name  = azurerm_resource_group.rg.name

  azure_active_directory_role_based_access_control {
    admin_group_object_ids = var.admin_group_object_ids
    azure_rbac_enabled     = true
    managed                = true
    tenant_id              = var.tenant_id
  }

  default_node_pool {
    enable_auto_scaling = true
    max_count           = 10
    min_count           = 1
    name                = "system"
    os_disk_type        = "Ephemeral"
    type                = "VirtualMachineScaleSets"
    tags                = var.tags
    vm_size             = var.vm_sku
    vnet_subnet_id      = azurerm_subnet.subnet-1.id
    zones               = var.zones
  }

  identity {
    type = "SystemAssigned"
  }

  linux_profile {
    admin_username = var.admin_username
    ssh_key {
      key_data = var.ssh_key
    }
  }

  depends_on = [
    azurerm_subnet.subnet-1,
    azurerm_subnet.subnet-2,
  ]
}

resource "azurerm_kubernetes_cluster_node_pool" "nodepool-user" {
  enable_auto_scaling   = true
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks.id
  max_count             = 10
  min_count             = 1
  name                  = "linux"
  os_disk_type          = "Ephemeral"
  tags                  = var.tags
  vm_size               = var.vm_sku
  vnet_subnet_id        = azurerm_subnet.subnet-2.id
  zones                 = var.zones
  depends_on = [
    azurerm_kubernetes_cluster.aks,
    azurerm_subnet.subnet-2,
  ]
}
