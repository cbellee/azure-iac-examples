resource "azurerm_virtual_network" "res-1" {
  address_space       = ["10.0.0.0/16"]
  location            = "australiaeast"
  name                = "aztfydemo-vnet"
  resource_group_name = "aztfydemo-rg"
  tags = {
    costcentre = "123456789"
  }
  depends_on = [
    azurerm_resource_group.res-10,
  ]
}

resource "azurerm_subnet" "res-6" {
  address_prefixes                               = ["10.0.8.0/21"]
  enforce_private_link_endpoint_network_policies = true
  name                                           = "aks-user-subnet"
  resource_group_name                            = "aztfydemo-rg"
  virtual_network_name                           = "aztfydemo-vnet"
  depends_on = [
    azurerm_virtual_network.res-1,
  ]
}

resource "azurerm_kubernetes_cluster_node_pool" "res-8" {
  enable_auto_scaling   = true
  kubernetes_cluster_id = "/subscriptions/b2375b5f-8dab-4436-b87c-32bc7fdce5d0/resourceGroups/aztfydemo-rg/providers/Microsoft.ContainerService/managedClusters/aks-aztfydemo"
  max_count             = 10
  min_count             = 1
  name                  = "linux"
  os_disk_type          = "Ephemeral"
  tags = {
    costcentre = "123456789"
  }
  vm_size        = "Standard_F8s_v2"
  vnet_subnet_id = "/subscriptions/b2375b5f-8dab-4436-b87c-32bc7fdce5d0/resourceGroups/aztfydemo-rg/providers/Microsoft.Network/virtualNetworks/aztfydemo-vnet/subnets/aks-user-subnet"
  zones          = ["1", "2", "3"]
  depends_on = [
    azurerm_kubernetes_cluster.myaks,
    azurerm_subnet.res-6,
  ]
}
resource "azurerm_resource_group" "res-10" {
  location = "australiaeast"
  name     = "aztfydemo-rg"
}
resource "azurerm_container_registry" "res-0" {
  admin_enabled       = true
  location            = "australiaeast"
  name                = "aztfydemoacro2fzihlnc5e6m"
  resource_group_name = "aztfydemo-rg"
  sku                 = "Premium"
  tags = {
    costcentre = "123456789"
  }
  depends_on = [
    azurerm_resource_group.res-10,
  ]
}

resource "azurerm_subnet" "res-5" {
  address_prefixes                               = ["10.0.0.0/21"]
  enforce_private_link_endpoint_network_policies = true
  name                                           = "aks-system-subnet"
  resource_group_name                            = "aztfydemo-rg"
  virtual_network_name                           = "aztfydemo-vnet"
  depends_on = [
    azurerm_virtual_network.res-1,
  ]
}
resource "azurerm_kubernetes_cluster" "myaks" {
  azure_policy_enabled = true
  dns_prefix           = "aztfydemo"
  location             = "australiaeast"
  name                 = "aks-aztfydemo"
  resource_group_name  = "aztfydemo-rg"
  azure_active_directory_role_based_access_control {
    admin_group_object_ids = ["f6a900e2-df11-43e7-ba3e-22be99d3cede"]
    azure_rbac_enabled     = true
    managed                = true
    tenant_id              = "3d49be6f-6e38-404b-bbd4-f61c1a2d25bf"
  }
  default_node_pool {
    enable_auto_scaling = true
    max_count           = 10
    min_count           = 1
    name                = "system"
    os_disk_type        = "Ephemeral"
    tags = {
      costcentre = "123456789"
    }
    vm_size        = "Standard_F8s_v2"
    vnet_subnet_id = "/subscriptions/b2375b5f-8dab-4436-b87c-32bc7fdce5d0/resourceGroups/aztfydemo-rg/providers/Microsoft.Network/virtualNetworks/aztfydemo-vnet/subnets/aks-system-subnet"
    zones          = ["1", "2", "3"]
  }
  identity {
    type = "SystemAssigned"
  }
  linux_profile {
    admin_username = "localadmin"
    ssh_key {
      key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCKEnblRrHUsUf2zEhDC4YrXVDTf6Vj3eZhfIT22og0zo2hdpfUizcDZ+i0J4Bieh9zkcsGMZtMkBseMVVa5tLSNi7sAg79a8Bap5RmxMDgx53ZCrJtTC3Li4e/3xwoCjnl5ulvHs6u863G84o8zgFqLgedKHBmJxsdPw5ykLSmQ4K6Qk7VVll6YdSab7R6NIwW5dX7aP2paD8KRUqcZ1xlArNhHiUT3bWaFNRRUOsFLCxk2xyoXeu+kC9HM2lAztIbUkBQ+xFYIPts8yPJggb4WF6Iz0uENJ25lUGen4svy39ZkqcK0ZfgsKZpaJf/+0wUbjqW2tlAMczbTRsKr8r cbellee@CB-SBOOK-1809"
    }
  }
  depends_on = [
    azurerm_subnet.res-6,
    azurerm_subnet.res-5,
  ]
}
resource "azurerm_kubernetes_cluster_node_pool" "res-9" {
  enable_auto_scaling   = true
  kubernetes_cluster_id = "/subscriptions/b2375b5f-8dab-4436-b87c-32bc7fdce5d0/resourceGroups/aztfydemo-rg/providers/Microsoft.ContainerService/managedClusters/aks-aztfydemo"
  max_count             = 10
  min_count             = 1
  mode                  = "System"
  name                  = "system"
  os_disk_type          = "Ephemeral"
  tags = {
    costcentre = "123456789"
  }
  vm_size        = "Standard_F8s_v2"
  vnet_subnet_id = "/subscriptions/b2375b5f-8dab-4436-b87c-32bc7fdce5d0/resourceGroups/aztfydemo-rg/providers/Microsoft.Network/virtualNetworks/aztfydemo-vnet/subnets/aks-system-subnet"
  zones          = ["1", "2", "3"]
  depends_on = [
    azurerm_kubernetes_cluster.myaks,
    azurerm_subnet.res-5,
  ]
}