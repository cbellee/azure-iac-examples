variable "resource_group_name" {
  type = string
  default = "ado-vmss-agent-pool-rg"
  description = "Azure Resource Group Name"
}

variable "cluster_name" {
  type = string
  default = "ado-vmss-aks"
  description = "Azure Kubernetes Service Cluster Name"
}

variable "tenant_id" {
  type = string
  default = ""
  description = "Azure Tenant ID"
}

variable "subscription_id" {
  type = string
  default = ""
  description = "Azure Subscription ID"
}

variable "aad_server_id" {
  type = string
  default = "6dae42f8-4368-4678-94ff-3960e28e3630"
  description = "Azure Kubernetes Service AAD Server"
}

variable "client_id" {
  type = string
  default = ""
  description = "Managed Identity Client ID"
}

