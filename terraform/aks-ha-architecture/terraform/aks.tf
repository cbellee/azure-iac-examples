locals {
  region1_blue_aks_cluster_name  = "${var.prefix}-${var.region1.locationShortName}-blue-aks"
  region1_green_aks_cluster_name = "${var.prefix}-${var.region1.locationShortName}-green-aks"
  region2_blue_aks_cluster_name  = "${var.prefix}-${var.region2.locationShortName}-blue-aks"
  region2_green_aks_cluster_name = "${var.prefix}-${var.region2.locationShortName}-green-aks"
}

resource azurerm_kubernetes_cluster "region1_blue_aks_cluster" {
  name                    = local.region1_blue_aks_cluster_name
  location                = azurerm_resource_group.region1_rg.location
  resource_group_name     = azurerm_resource_group.region1_rg.name
  dns_prefix              = local.region1_blue_aks_cluster_name
  kubernetes_version      = var.kubernetesVersion
  private_cluster_enabled = true

  addon_profile {
    kube_dashboard {
      enabled = true
    }
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.region1_workspace.id
    }
  }

  linux_profile {
    admin_username = "localadmin"
    ssh_key {
      key_data = var.sshKey
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
    vnet_subnet_id      = azurerm_subnet.region1_spoke_subnet_1.id
    enable_auto_scaling = true
    name                = "default"
    type                = "VirtualMachineScaleSets"
    max_count           = 5
    min_count           = 1
    node_count          = 1
    vm_size             = var.aksNodeSku
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

# region 2
resource azurerm_kubernetes_cluster "region1_green_aks_cluster" {
  name                    = local.region1_green_aks_cluster_name
  location                = azurerm_resource_group.region1_rg.location
  resource_group_name     = azurerm_resource_group.region1_rg.name
  dns_prefix              = local.region1_green_aks_cluster_name
  kubernetes_version      = var.kubernetesVersion
  private_cluster_enabled = true

  addon_profile {
    kube_dashboard {
      enabled = true
    }
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.region1_workspace.id
    }
  }

  linux_profile {
    admin_username = "localadmin"
    ssh_key {
      key_data = var.sshKey
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
    vnet_subnet_id      = azurerm_subnet.region1_spoke_subnet_2.id
    enable_auto_scaling = true
    name                = "default"
    type                = "VirtualMachineScaleSets"
    max_count           = 5
    min_count           = 1
    node_count          = 1
    vm_size             = var.aksNodeSku
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

locals {
  region2_blue_aks_cluster_name  = "${var.prefix}-${var.region2.locationShortName}-blue-aks"
  region2_green_aks_cluster_name = "${var.prefix}-${var.region2.locationShortName}-green-aks"
}

resource azurerm_kubernetes_cluster "region2_blue_aks_cluster" {
  name                    = local.region2_blue_aks_cluster_name
  location                = azurerm_resource_group.region2_rg.location
  resource_group_name     = azurerm_resource_group.region2_rg.name
  dns_prefix              = local.region2_blue_aks_cluster_name
  kubernetes_version      = var.kubernetesVersion
  private_cluster_enabled = true

  addon_profile {
    kube_dashboard {
      enabled = true
    }
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.region2_workspace.id
    }
  }

  linux_profile {
    admin_username = "localadmin"
    ssh_key {
      key_data = var.sshKey
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
    vnet_subnet_id      = azurerm_subnet.region2_spoke_subnet_1.id
    enable_auto_scaling = true
    name                = "default"
    type                = "VirtualMachineScaleSets"
    max_count           = 5
    min_count           = 1
    node_count          = 1
    vm_size             = var.aksNodeSku
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

# region 2
resource azurerm_kubernetes_cluster "region2_green_aks_cluster" {
  name                    = local.region2_green_aks_cluster_name
  location                = azurerm_resource_group.region2_rg.location
  resource_group_name     = azurerm_resource_group.region2_rg.name
  dns_prefix              = local.region2_green_aks_cluster_name
  kubernetes_version      = var.kubernetesVersion
  private_cluster_enabled = true

  addon_profile {
    kube_dashboard {
      enabled = true
    }
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.region2_workspace.id
    }
  }

  linux_profile {
    admin_username = "localadmin"
    ssh_key {
      key_data = var.sshKey
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
    vnet_subnet_id      = azurerm_subnet.region2_spoke_subnet_2.id
    enable_auto_scaling = true
    name                = "default"
    type                = "VirtualMachineScaleSets"
    max_count           = 5
    min_count           = 1
    node_count          = 1
    vm_size             = var.aksNodeSku
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
