output "host" {
  value = azurerm_kubernetes_cluster.aks.kube_config.0.host
  sensitive = true
}

output "client_certificate" {
  value     = azurerm_kubernetes_cluster.aks.kube_config.0.client_certificate
  sensitive = true
}

output "client_key" {
  value     = azurerm_kubernetes_cluster.aks.kube_config.0.client_key
  sensitive = true
}

output "ca_certificate" {
  value     = azurerm_kubernetes_cluster.aks.kube_config.0.cluster_ca_certificate
  sensitive = true
}

output "kube_config" {
  value     = azurerm_kubernetes_cluster.aks.kube_config_raw
  sensitive = true
}

output "kubernetes_cluster_name" {
  value     = azurerm_kubernetes_cluster.aks.name
  sensitive = false
}

output "compute_resource_group_name" {
  value     = azurerm_kubernetes_cluster.aks.resource_group_name
  sensitive = false
}
