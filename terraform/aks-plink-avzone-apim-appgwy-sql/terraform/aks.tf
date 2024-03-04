resource azurerm_kubernetes_cluster "aks_cluster" {
  name                    = "${var.prefix}-aks-cluster"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  dns_prefix              = "${var.prefix}-aks-cluster"
  kubernetes_version      = var.kubernetes_version
  private_cluster_enabled = true

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.workspace.id
    }
  }

  linux_profile {
    admin_username = "localadmin"
    ssh_key {
      key_data = var.ssh_key
    }
  }

  network_profile {
    load_balancer_sku  = "Standard"
    network_plugin     = "azure"
    dns_service_ip     = "172.29.0.10"
    docker_bridge_cidr = "172.29.16.1/20"
    service_cidr       = "172.29.0.0/20"
  }

  default_node_pool {
    vnet_subnet_id      = azurerm_subnet.subnet_2.id
    enable_auto_scaling = true
    availability_zones  = ["1", "2", "3"]
    name                = "default"
    type                = "VirtualMachineScaleSets"
    max_count           = 5
    min_count           = 1
    node_count          = 1
    vm_size             = var.aks_node_sku
    max_pods            = var.max_pods
    os_disk_size_gb     = 250
    tags                = var.tags
  }

  identity {
    type = "SystemAssigned"
  }

/*   role_based_access_control {
    enabled = true
    azure_active_directory {
      managed                = true
      admin_group_object_ids = [var.aks_admin_group_object_id]
    }
  } */

  tags = var.tags
}
