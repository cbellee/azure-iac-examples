variable "prefix" {
    type = string
    default = "cbellee"
}

variable "location" {
    type = string
    default = "australiaeast"
}

variable "resource-group-name" {
    type = string
    default = "tf-layering-application-rg"
}

variable "tags" {
    type = map(string)
    default = {
      "environment" = "dev"
    }
}