locals {
  aks_cluster_name = "${var.prefix}-cluster"
}

resource azurerm_kubernetes_cluster "aks_cluster" {
  name                    = local.aks_cluster_name
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  dns_prefix              = local.aks_cluster_name
  kubernetes_version      = var.kubernetes_version
  private_cluster_enabled = true
  role_based_access_control_enabled = true

  linux_profile {
    admin_username = var.admin_username
    ssh_key {
      key_data = var.ssh_key
    }
  }

  network_profile {
    load_balancer_sku  = "standard"
    network_plugin     = "azure"
    dns_service_ip     = "10.100.1.10"
    service_cidr       = "10.100.1.0/24"
    outbound_type      = "userDefinedRouting"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id
  }

  default_node_pool {
    vnet_subnet_id      = azurerm_subnet.spoke_subnet_1.id
    enable_auto_scaling = true
    name                = "default"
    type                = "VirtualMachineScaleSets"
    max_count           = 5
    min_count           = 1
    vm_size             = var.aks_node_sku
    max_pods            = var.max_pods
    os_disk_size_gb     = 250
    tags                = var.tags
  }

  identity {
    type = "SystemAssigned"
  }

  tags = var.tags

  depends_on = [
    azurerm_subnet_route_table_association.spoke_subnet_1_route_table
  ]
}
