resource azurerm_resource_group "rg" {
  name     = "${var.prefix}-${lower(random_id.unique_name.hex)}-rg"
  location = var.location
  tags     = var.tags
}
