data "terraform_remote_state" "compute" {
  backend = "azurerm"
  config = {
    resource_group_name      = "tf-state-rg"
    storage_account_name     = "tfstatestorcbellee452023"
    container_name           = "20-compute-tf-state"
    key                      = "terraform.tfstate"
  }
}

data "azurerm_kubernetes_cluster" "cluster" {
  name                = data.terraform_remote_state.compute.outputs.kubernetes_cluster_name
  resource_group_name = data.terraform_remote_state.compute.outputs.compute_resource_group_name
}

provider "kubernetes" {
  host = data.terraform_remote_state.compute.outputs.host
  client_certificate     = base64decode(data.terraform_remote_state.compute.outputs.client_certificate)
  client_key             = base64decode(data.terraform_remote_state.compute.outputs.client_key)
  cluster_ca_certificate = base64decode(data.terraform_remote_state.compute.outputs.ca_certificate)
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "scalable-nginx-example"
    labels = {
      App = "ScalableNginxExample"
    }
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        App = "ScalableNginxExample"
      }
    }
    template {
      metadata {
        labels = {
          App = "ScalableNginxExample"
        }
      }
      spec {
        container {
          image = "nginx:1.7.8"
          name  = "example"
          port {
            container_port = 80
          }
          resources {
            limits = {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests = {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx" {
  metadata {
    name = "nginx-example"
  }
  spec {
    selector = {
      App = kubernetes_deployment.nginx.spec.0.template.0.metadata[0].labels.App
    }
    port {
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"
  }
}
