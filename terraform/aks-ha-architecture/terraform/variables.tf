variable "tags" {
  default = {
    "environment" = "test"
    "costcentre"  = "12345"
  }
}

variable "prefix" {
  default = "aks-ha"
}

variable "region1" {
  type = object({
    resourceGroupName = string,
    location          = string,
    locationShortName = string,
    hubVnet = object({
      prefix = string,
      subnets = list(object({
        name    = string
        address = string
      }))
    }),
    spokeVnet = object({
      prefix = string,
      subnets = list(object({
        name    = string
        address = string
      }))
    })
  })
  default = {
    resourceGroupName = "aks-ha-aue-rg"
    location          = "australiaeast"
    locationShortName = "aue"
    hubVnet = {
      prefix = "10.1.0.0/16"
      subnets = [
        {
          name    = "AzureFirewallSubnet"
          address = "10.1.1.0/24"
        },
        {
          name    = "AzureAppGatewaySubnet"
          address = "10.1.2.0/24"
        },
        {
          name    = "BastionSubnet"
          address = "10.1.3.0/24"
        }
      ]
    }
    spokeVnet = {
      prefix = "10.2.0.0/16"
      subnets = [
        {
          name    = "AKSBlueSubnet"
          address = "10.2.1.0/24"
        },
        {
          name    = "AKSGreenSubnet"
          address = "10.2.2.0/24"
        }
      ]
    }
  }
}

variable "region2" {
  type = object({
    resourceGroupName = string,
    location          = string,
    locationShortName = string,
    hubVnet = object({
      prefix = string,
      subnets = list(object({
        name    = string
        address = string
      }))
    }),
    spokeVnet = object({
      prefix = string,
      subnets = list(object({
        name    = string
        address = string
      }))
    })
  })
  default = {
    resourceGroupName = "aks-ha-aus-rg"
    location          = "australiasoutheast"
    locationShortName = "aus"
    hubVnet = {
      prefix = "10.3.0.0/16"
      subnets = [
        {
          name    = "AzureFirewallSubnet"
          address = "10.3.1.0/24"
        },
        {
          name    = "AzureAppGatewaySubnet"
          address = "10.3.2.0/24"
        },
        {
          name    = "BastionSubnet"
          address = "10.3.3.0/24"
        }
      ]
    }
    spokeVnet = {
      prefix = "10.4.0.0/16"
      subnets = [
        {
          name    = "AKSBlueSubnet"
          address = "10.4.1.0/24"
        },
        {
          name    = "AKSGreenSubnet"
          address = "10.4.2.0/24"
        }
      ]
    }
  }
}

variable "kubernetesVersion" {
  type    = string
  default = "1.16.9"
}

variable "aksNodeSku" {
  type    = string
  default = "Standard_F2s_v2"

}

variable "bastionVmSku" {
  type    = string
  default = "Standard_F2s_v2"
}

variable "sshKey" {
  type    = string
}
