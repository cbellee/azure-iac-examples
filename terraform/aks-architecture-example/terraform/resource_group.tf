resource azurerm_resource_group "rg" {
    for_each = toset(var.resource_groups)

    name = "${var.prefix}-${each.value}"
    location = var.location
    tags = var.tags
}
