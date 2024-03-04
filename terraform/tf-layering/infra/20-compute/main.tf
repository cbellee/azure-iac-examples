data "terraform_remote_state" "network" {
  backend = "azurerm"
  config  = {
    resource_group_name      = "tf-state-rg"
    storage_account_name     = "tfstatestorcbellee452023"
    container_name           = "10-network-tf-state"
    key                      = "terraform.tfstate"
  }
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource-group-name
  location = var.location
  tags     = var.tags
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "log-analytics-01"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# this rule is looking at a deprecated property, so ignore it for now
#tfsec:ignore:azure-container-limit-authorized-ips
resource "azurerm_kubernetes_cluster" "aks" {
  name                              = "cluster-01"
  tags                              = var.tags
  location                          = azurerm_resource_group.rg.location
  resource_group_name               = azurerm_resource_group.rg.name
  dns_prefix                        = "cbellee"
  azure_policy_enabled              = true
  role_based_access_control_enabled = true

/*   api_server_access_profile {
        authorized_ip_ranges = [
            var.external-ip,
            var.ado-ip
        ]
  } */

    network_profile {
        network_plugin    = "azure"
        load_balancer_sku = "standard"
        service_cidr      = "192.168.0.0/24"
        dns_service_ip    = "192.168.0.10"
        network_policy    = "azure"
    }

    default_node_pool {
        name                = "default"
        node_count          = 1
        vm_size             = "Standard_D4_v2"
        vnet_subnet_id      = data.terraform_remote_state.network.outputs.node_subnet.id
        pod_subnet_id       = data.terraform_remote_state.network.outputs.pod_subnet.id
        enable_auto_scaling = true
        max_count           = 3
        min_count           = 1
        type                = "VirtualMachineScaleSets"
        os_disk_size_gb     = 30
        max_pods            = 80
    }

    identity {
        type = "SystemAssigned"
    }

    oms_agent {
        log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
    }
}
