output "kv-name" {
  value = azurerm_key_vault.kv.name
}

output "kv-resource-id" {
  value = azurerm_key_vault.kv.id
}

output "aks-node-rg" {
  value = azurerm_kubernetes_cluster.aks_cluster.node_resource_group
}

output "aks-cluster-name" {
  value = azurerm_kubernetes_cluster.aks_cluster.name
}

output "aks-cluster-id" {
  value = azurerm_kubernetes_cluster.aks_cluster.id
}

output "kube-config" {
  value = azurerm_kubernetes_cluster.aks_cluster.kube_config_raw
}

output "resource-group-name" {
  value = azurerm_resource_group.rg.name
}
