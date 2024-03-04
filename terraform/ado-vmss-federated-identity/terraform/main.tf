 
data "azurerm_kubernetes_cluster" "cluster" {
  name                = var.cluster_name
  resource_group_name = var.resource_group_name
}

provider "kubernetes" {
  host                   = "${data.azurerm_kubernetes_cluster.cluster.kube_config.0.host}"
  client_certificate     = "${base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)}"
  client_key             = "${base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)}"
  cluster_ca_certificate = "${base64decode(data.azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)}"
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command = "kubelogin"
    args = [
      "get-token",
      "--login",
      "msi",
      "--environment",
      "AzurePublicCloud",
      "--server-id",
      var.aad_server_id,
      "--client-id",
      var.client_id
    ]
  }
}

resource "kubernetes_namespace" "test" {
  metadata {
    name = "nginx"
  }
}

resource "kubernetes_deployment" "test" {
  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace.test.metadata.0.name
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "MyTestApp"
      }
    }
    template {
      metadata {
        labels = {
          app = "MyTestApp"
        }
      }
      spec {
        container {
          image = "nginx"
          name  = "nginx-container"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "test" {
  metadata {
    name      = "nginx"
    namespace = kubernetes_namespace.test.metadata.0.name
  }
  spec {
    selector = {
      app = kubernetes_deployment.test.spec.0.template.0.metadata.0.labels.app
    }
    type = "NodePort"
    port {
      node_port   = 30201
      port        = 80
      target_port = 80
    }
  }
}