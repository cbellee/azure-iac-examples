variable "tags" {
}

variable "prefix" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "aks_admin_group_object_id" {
  type = string
}

variable "aks_node_sku" {
  type = string
}

variable "max_pods" {
  type = string
}

variable "bastion_vm_sku" {
  type = string
}

variable "ssh_key" {
  type = string
}

variable "pgres_admin" {
  type = string
}

variable "pgres_password" {
  type = string
}

variable "azsql_admin" {
  type = string
}

variable "azsql_password" {
  type = string
}

variable "kv_access_policy_user_object_id" {
  type = string
}

data local_file "cloudinit" {
  filename = "./cloudinit.txt"
}
