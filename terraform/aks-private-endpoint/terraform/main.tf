terraform {
backend "azurerm" {
  storage_account_name = "tfstatestorcbellee452023"
  container_name = "aks-federated-identity-tf-demo"
  key = "tfstate"
  subscription_id = "b2375b5f-8dab-4436-b87c-32bc7fdce5d0"
  tenant_id = "3d49be6f-6e38-404b-bbd4-f61c1a2d25bf"
  resource_group_name = "tf-state-rg"
}

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
    azuredevops = {
      source = "microsoft/azuredevops"
      version = ">= 0.9.0"
    }
  }
}

provider "azurerm" {
  features {} 
  //use_msi = true
}

provider "azuredevops" {
  org_service_url = "https://dev.azure.com/kainidev"
  personal_access_token = var.ado_pat_token
}

resource "random_string" "random" {
  length  = 16
  special = false
  keepers = { version = "v1" }
}
