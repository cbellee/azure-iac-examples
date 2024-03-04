locals {
  aks_cluster_name = "${var.prefix}-cluster"
}

resource azurerm_kubernetes_cluster "aks_cluster" {
  name                    = local.aks_cluster_name
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  dns_prefix              = local.aks_cluster_name
  kubernetes_version      = var.kubernetes_version

  addon_profile {
    kube_dashboard {
      enabled = true
    }
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
    dns_service_ip     = "10.100.1.10"
    docker_bridge_cidr = "172.17.0.1/16"
    service_cidr       = "10.100.1.0/24"
  }

  default_node_pool {
    vnet_subnet_id      = azurerm_subnet.spoke_subnet_1.id
    enable_auto_scaling = true
    name                = "default"
    type                = "VirtualMachineScaleSets"
    max_count           = 5
    min_count           = 1
    node_count          = 1
    vm_size             = var.aks_node_sku
    max_pods            = 200
    os_disk_size_gb     = 250
    tags                = var.tags
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control {
    enabled = true
  }

  tags = var.tags
}
