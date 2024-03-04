variable "tags" {
  default = {
    "environment" = "test"
    "costcentre"  = "12345"
  }
}

variable "prefix" {
  default = "aks-az"
}

variable "location" {
  default = "southeastasia"
}

variable "kubernetes_version" {
  type    = string
  default = "1.17.7"
}

variable "aks_node_sku" {
  type    = string
  default = "Standard_F2s_v2"
}

variable "max_pods" {
  type = number
  default = 50
}

variable "os_disk_size_gb" {
  type = number
  default = 250
}

variable "ssh_key" {
  type = string
}
