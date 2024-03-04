terraform {
  required_version = ">=1.3.0"

backend "azurerm" {
    subscription_id        = "b2375b5f-8dab-4436-b87c-32bc7fdce5d0"
    tenant_id              = "3d49be6f-6e38-404b-bbd4-f61c1a2d25bf"
    resource_group_name    = "tf-state-rg"
    storage_account_name   = "tfstatestorcbellee452023"
    container_name         = "kv-pe-tf-state"
    key                    = "terraform.tfstate"
}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.40.0"
    }
  }
}

provider "azurerm" {
  features {}
}