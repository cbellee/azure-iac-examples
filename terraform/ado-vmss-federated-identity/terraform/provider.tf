provider "azurerm" {
  features {
  }
  # use_msi = true
  use_oidc = true
}

terraform {
backend "azurerm" {
}

required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">=3.0.0"
    }
        kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.0.0"
    }
  }
}