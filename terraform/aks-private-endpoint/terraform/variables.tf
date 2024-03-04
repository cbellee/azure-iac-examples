variable "tags" {
}

variable "environment" {
}

variable "prefix" {
  default = "aks-tf-private"
}

variable "resource_group_name" {
  default = "aks-tf-private-cluster-rg"
}

variable "location" {
  default = "australiaeast"
}

variable "kubernetes_version" {
  type    = string
  default = "1.28.0"
}

variable "aks_node_sku" {
  type    = string
  default = "Standard_D2_v2"
}

variable "max_pods" {
  type = string
  default = 30
}

variable "bastion_vm_sku" {
  type    = string
  default = "Standard_F2s_v2"
}

variable "admin_username" {
  type = string
  default = "localadmin"
}

variable "ssh_key" {
  type = string
}

variable "on_premises_router_public_ip_address" {
  type = string
  default = "60.230.2.9"
}

variable "on_premises_router_private_cidr" {
  type = string
  default = "192.168.88.0/24"
}

variable "ado_pat_token" {
  type = string
}

data local_file "cloudinit" {
  filename = "./cloudinit.txt"
}
