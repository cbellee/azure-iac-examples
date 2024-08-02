# nonprod-cluster
resource azurerm_kubernetes_cluster "nonprod_cluster" {

  name                    = "${var.prefix}-nonprod-cluster"
  location                = azurerm_resource_group.rg["nonprod-aks-rg"].location
  resource_group_name     = azurerm_resource_group.rg["nonprod-aks-rg"].name
  dns_prefix              = "${var.prefix}-nonprod-cluster"
  kubernetes_version      = var.kubernetes_version
  private_cluster_enabled = true
  node_resource_group     = "${var.prefix}-nonprod-aks-node-rg"

  linux_profile {
    admin_username = var.admin_user_name
    ssh_key {
      key_data = var.ssh_key
    }
  }

  network_profile {
    load_balancer_sku  = "standard"
    network_plugin     = "azure"
    dns_service_ip     = "10.100.1.10"
    outbound_type      = "userDefinedRouting"
  }

  default_node_pool {
    vnet_subnet_id      = element(tolist(azurerm_virtual_network.vnet["nonprod-spoke-vnet"].subnet),0).id
    enable_auto_scaling = true
    name                = "default"
    type                = "VirtualMachineScaleSets"
    max_count           = var.aks_max_node_count
    min_count           = var.aks_min_node_count
    node_count          = var.aks_node_count
    vm_size             = var.aks_node_sku
    max_pods            = var.aks_max_pods
    os_disk_size_gb     = 250
    tags                = var.tags
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  depends_on = [
    azurerm_subnet_route_table_association.nonprod_spoke_subnet_1_route_table_assoc,
  ]
}

# prod cluster
resource azurerm_kubernetes_cluster "prod_cluster" {

  name                    = "${var.prefix}-prod-cluster"
  location                = azurerm_resource_group.rg["prod-aks-rg"].location
  resource_group_name     = azurerm_resource_group.rg["prod-aks-rg"].name
  dns_prefix              = "${var.prefix}-prod-cluster"
  kubernetes_version      = var.kubernetes_version
  private_cluster_enabled = true
  node_resource_group     = "${var.prefix}-prod-aks-node-rg"

  linux_profile {
    admin_username = var.admin_user_name
    ssh_key {
      key_data = var.ssh_key
    }
  }

  network_profile {
    load_balancer_sku  = "standard"
    network_plugin     = "azure"
    dns_service_ip     = "10.100.1.10"
    outbound_type      = "userDefinedRouting"
  }

  default_node_pool {
    vnet_subnet_id      = element(tolist(azurerm_virtual_network.vnet["prod-spoke-vnet"].subnet),0).id
    enable_auto_scaling = true
    name                = "default"
    type                = "VirtualMachineScaleSets"
    max_count            = var.aks_max_node_count
    min_count           = var.aks_min_node_count
    node_count          = var.aks_node_count
    vm_size             = var.aks_node_sku
    max_pods            = var.aks_max_pods
    os_disk_size_gb     = 250
    tags                = var.tags
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  depends_on = [
    azurerm_subnet_route_table_association.prod_spoke_subnet_1_route_table_assoc,
  ]
}
