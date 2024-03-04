variable "prefix" {
    type = string
    default = "cbellee"
}

variable "object_id" {
    type = string
    default = "963f10-818b-406d-a2f6-6e758d86e259"
}

variable admin_password {
    type = string
    default = "M1cr0soft1234567890"
}

variable admin_username {
    type = string
    default = "localadmin"
}

variable "subscription_id" {
    default  = "b2375b5f-8dab-4436-b87c-32bc7fdce5d0"
    type = string
}

variable "tenant_id" {
    type = string
    default = "3d49be6f-6e38-404b-bbd4-f61c1a2d25bf"    
}

variable "location" {
    type = string
    default = "australiaeast"
}

variable "resource-group-name" {
    type = string
    default = "tf-kv-pe-rg"
}

variable "tags" {
    type = map(string)
    default = {
      "environment" = "dev"
      "tier"        = 0
    }
}