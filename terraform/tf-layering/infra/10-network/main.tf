resource "azurerm_resource_group" "rg" {
  name     = var.resource-group-name
  location = var.location
  tags     = var.tags
}

module "virtual_network" {
  source              = "aztfm/virtual-network/azurerm"
  version             = ">=3.0.0"
  name                = "${var.prefix}-vnet"
  tags                = var.tags
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
  subnets = [
    { 
      name = "node-subnet", 
      address_prefixes = ["10.0.1.0/24"], 
      tags = merge({"subnet-name" = "node-subnet"}, var.tags)
    },
    { 
      name = "pod-subnet", 
      address_prefixes = ["10.0.2.0/24"], 
      tags = merge({"subnet-name" = "pod-subnet"}, var.tags)
      delegation = "Microsoft.ContainerService/managedClusters"
    },
    { 
      name = "sep-subnet", 
      address_prefixes = ["10.0.3.0/24"],
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"],
      tags = merge({"subnet-name" = "sep-subnet"}, var.tags)
    },
  ]
}
