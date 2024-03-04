terraform {
  required_version = ">= 0.12"
  backend "azurerm" {
    resource_group_name  = "terraform-rg"
    storage_account_name = "stortf38f883"
    container_name       = "terraform-state"
    key                  = "terraform-aks-plink-avzone-apim-appgwy-sql.tfstate"
  }
}

provider "azurerm" {
  version = "~> 2.7.0"
  features {
  }
}

data "azurerm_client_config" "current" {
}

resource "random_string" "random" {
  length  = 8
  special = false
  keepers = { version = "v2" }
}
