locals {
  aks_cluster_name = "${var.prefix}-aks"
}

resource azurerm_kubernetes_cluster_node_pool "aks_cluster_node_pool_2" {
  kubernetes_cluster_id = azurerm_kubernetes_cluster.aks_cluster.id
  name                = "pool1"
  vnet_subnet_id      = azurerm_subnet.spoke_subnet_2.id
  enable_auto_scaling = true
  vm_size             = var.aks_node_sku
  availability_zones  = ["1","2","3"]
  max_pods            = var.max_pods
  max_count           = 5
  min_count           = 1
  node_count          = 3
  os_disk_size_gb     = var.os_disk_size_gb
}

resource azurerm_kubernetes_cluster "aks_cluster" {
  name                    = local.aks_cluster_name
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  dns_prefix              = local.aks_cluster_name
  kubernetes_version      = var.kubernetes_version

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
    dns_service_ip     = "10.100.1.10"
    docker_bridge_cidr = "172.17.0.1/16"
    service_cidr       = "10.100.1.0/24"
  }

  default_node_pool {
    vnet_subnet_id      = azurerm_subnet.spoke_subnet_1.id
    enable_auto_scaling = true
    name                = "default"
    type                = "VirtualMachineScaleSets"
    availability_zones  = ["1","2","3"]
    max_count           = 5
    min_count           = 1
    node_count          = 2
    vm_size             = var.aks_node_sku
    max_pods            = var.max_pods
    os_disk_size_gb     = var.os_disk_size_gb
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
