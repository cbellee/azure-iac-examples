output "prod-aks-node-rg" {
  value = azurerm_kubernetes_cluster.prod_cluster.node_resource_group
}

output "nonprod-aks-node-rg" {
  value = azurerm_kubernetes_cluster.nonprod_cluster.node_resource_group
}

output "prod-cluster-name" {
  value = azurerm_kubernetes_cluster.prod_cluster.name
}

output "nonprod-cluster-name" {
  value = azurerm_kubernetes_cluster.nonprod_cluster.name
}

output "prod-cluster-id" {
  value = azurerm_kubernetes_cluster.prod_cluster.id
}

output "nonprod-cluster-id" {
  value = azurerm_kubernetes_cluster.nonprod_cluster.id
}

output "prod-cluster-private-fqdn" {
  value = azurerm_kubernetes_cluster.prod_cluster.private_fqdn
}

output "nonprod-cluster-private-fqdn" {
  value = azurerm_kubernetes_cluster.nonprod_cluster.private_fqdn
}
