variable "tenant_id" {
}

variable "tags" {
  default = {
    "environment" = "test"
    "costcentre"  = "12345"
  }
}

variable "prefix" {
  default = "aks-csi-pod-id-demo"
}

variable "location" {
  default = "australiaeast"
}

variable "resourceGroupName" {
  default = "aks-csi-pod-id-demo-rg"
}

variable "kubernetesVersion" {
  type    = string
  default = "1.18.8"
}

variable "aksNodeSku" {
  type    = string
  default = "Standard_F2s_v2"
}

variable "csi_provider_demo_key_vault_user_password" {
  type = string
}

variable "csi_provider_demo_key_vault_user_name" {
  type    = string
  default = "csi-provider-demo-key-vault-user"
}

variable "azure-service-connection-objectid" {
	type = string
}

variable "csi_provider_demo_domain_suffix" {
  type    = string
  default = "kainiindustries.net"
}

variable "secret_name" {
  default = "mysecret"
}

variable "secret_value" {
  default = "1234567890"
}

variable "ssh_key" {
  type = string
}
