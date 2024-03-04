output "node_subnet" {
    value = module.virtual_network.subnets["node-subnet"]
}

output "pod_subnet" {
    value = module.virtual_network.subnets["pod-subnet"]
}