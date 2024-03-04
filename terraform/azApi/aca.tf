terraform {
  required_providers {
    azapi = {
      source = "Azure/azapi"
    }
  }
}

provider "azapi" {
}

provider "azurerm" {
  features {}
}

resource azurerm_resource_group rg {
  name     = "aca-test-rg"
  location = "Australia East"
}

resource azurerm_log_analytics_workspace logs {
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  name = "log-analytics"
  sku = "Standard"
}

resource azapi_resource aca-env {
  type      = "Microsoft.App/managedEnvironments@2022-03-01"
  name      = "aca-test-env"
  parent_id = azurerm_resource_group.rg.id
  location  = azurerm_resource_group.rg.location
  body = jsonencode({
    properties = {
      appLogsConfiguration = {
        destination = "log-analytics"
        logAnalyticsConfiguration = {
          customerId = azurerm_log_analytics_workspace.logs.workspace_id
          sharedKey  = azurerm_log_analytics_workspace.logs.primary_shared_key
        }
      }
    }
  })
}

resource azapi_resource app {
  type      = "Microsoft.App/containerApps@2022-01-01-preview"
  name      = "podinfo"
  parent_id = azurerm_resource_group.rg.id
  location  = azurerm_resource_group.rg.location
  body = jsonencode({
    properties = {
      managedEnvironmentId = azapi_resource.aca-env.id
      configuration = {
        ingress = {
          targetPort = 9898
          external   = true
        }
        secrets = [
        ]
        registries = [
        ]
      }
      template = {
        containers = [
          {
            image = "stefanprodan/podinfo:6.1.8", // change to "stefanprodan/podinfo:6.2.0",
            name  = "podinfo"
            env = [
            ]
          }
        ]
      }
    }
  })
}