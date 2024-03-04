terraform {
  required_version = ">= 0.12"
  backend "azurerm" {
    resource_group_name  = "terraform-rg"
    storage_account_name = "stortf38f883"
    container_name       = "terraform-state"
    key                  = "terraform-aks-csi-provider.tfstate"
  }
}

provider "azurerm" {
  features {}
}

resource "random_id" "unique_name" {
  byte_length = 4
}