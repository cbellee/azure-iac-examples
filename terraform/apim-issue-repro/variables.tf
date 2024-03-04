variable "domain_name" {
    type = string
    default = "kainiindustries.net"
}

variable "apim_name" {
  type = string
  default = "repro-apim"
}

variable "rg_name" {
  type = string
  default = "repro-rg"
}

variable "location" {
  type = string
  default = "australiaeast"
}

variable "key_vault_name" {
  type = string
  default = "repro-kv"
}

variable "publisher_email" {
    type = string
    default = "cbellee@microsoft.com"
}

variable "sender_email" {
    type = string
    default = "cbellee@microsoft.com"
}

variable "apim_cert_password" {
  type = string
}

variable "apim_cert_name" {
  type = string
  default = "apim-client-cert"
}

variable "apim_cert_name_2" {
  type = string
  default = "apim-client-cert-2"
}

variable "vnet_name" {
    type = string
    default = "repro-vnet"
}

variable "user_object_id" {
    type = string
    default = "57963f10-818b-406d-a2f6-6e758d86e259"
}
