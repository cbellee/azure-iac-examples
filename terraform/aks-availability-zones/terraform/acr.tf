locals {
  acr_name = replace("${var.prefix}", "-", "")
}

resource "azurerm_container_registry" "acr" {
  name                     = "${local.acr_name}${lower(random_id.unique_name.hex)}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  sku                      = "Premium"
  admin_enabled            = true
}

resource "azurerm_role_assignment" "aks_acrpull_role_assignment" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.kubelet_identity.0.object_id
}
