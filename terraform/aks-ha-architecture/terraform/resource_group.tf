provider "azurerm" {
  features {}
}

resource azurerm_resource_group "region1_rg" {
    name = var.region1.resourceGroupName
    location = var.region1.location
    tags = var.tags
}

resource azurerm_resource_group "region2_rg" {
    name = var.region2.resourceGroupName
    location = var.region2.location
    tags = var.tags
}
