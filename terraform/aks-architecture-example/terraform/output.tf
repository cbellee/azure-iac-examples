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

output "prod-kube-config" {
  value = azurerm_kubernetes_cluster.prod_cluster.kube_config_raw
}

output "nonprod-kube-config" {
  value = azurerm_kubernetes_cluster.nonprod_cluster.kube_config_raw
}

/*
output "vnet-resource-group-name" {
  value = azurerm_resource_group.rg["network_rg"]
}

output "hub-vnet-id" {
  value = azurerm_virtual_network.vnet["hub_vnet"]
}

output "prod-spoke-vnet-id" {
  value = azurerm_virtual_network.vnet["prod_spoke_vnet"]
}

output "nonprod-spoke-vnet-id" {
  value = azurerm_virtual_network.vnet["nonprod_spoke_vnet"]
}
*/
