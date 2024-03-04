variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "environment" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "admin_group_object_ids" {
  type = list(string)
}

variable "vm_sku" {
  type = string
  default = "Standard_F8s_v2"
}

variable "admin_username" {
  default = "localadmin"
  type = string
}

variable "ssh_key" {
  type = string
}

variable "tags" {
  type = object({
    costcentre = string
    environment = string
  })
}

variable "vnet_address_space" {
  type = list(string)
  default = ["192.168.0.0/16"]
}

variable "subnet_1_name" {
  type = string
  default = "aks-system-subnet"
}

variable "subnet_2_name" {
  type = string
  default = "aks-user-subnet"
}

variable "subnet_3_name" {
  type = string
  default = "new-subnet"
}

variable "subnet_1_cidr" {
    type = list(string)
    default = ["192.168.1.0/24"]
}

variable "subnet_2_cidr" {
  type = list(string)
  default = ["192.168.2.0/24"]
}

variable "subnet_3_cidr" {
  type = list(string)
  default = ["192.168.3.0/24"]
}

variable "zones" {
  type = list(string)
  default = ["1", "2", "3"]  
}