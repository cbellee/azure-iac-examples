terraform {
  required_version = ">= 0.12"
  backend "azurerm" {
    resource_group_name  = "terraform-rg"
    storage_account_name = "stortf38f883"
    container_name       = "terraform-state"
    key                  = "terraform-aks-architecture-2.tfstate"
  }
}

provider "azurerm" {
  features {}
}