output "aks-node-rg" {
  value = azurerm_kubernetes_cluster.aks_cluster.node_resource_group
}

output "aks-cluster-name" {
  value = azurerm_kubernetes_cluster.aks_cluster.name
}

output "aks-cluster-id" {
  value = azurerm_kubernetes_cluster.aks_cluster.id
}

output "aks-cluster-private-fqdn" {
  value = azurerm_kubernetes_cluster.aks_cluster.private_fqdn
}

output "kube-config" {
  sensitive = true
  value = azurerm_kubernetes_cluster.aks_cluster.kube_config_raw
}

output "resource-group-name" {
  value = azurerm_resource_group.rg.name
}

output "hub-vnet-id" {
  value = azurerm_virtual_network.hub_vnet.id
}

output "spoke-vnet-id" {
  value = azurerm_virtual_network.spoke_vnet.id
}
