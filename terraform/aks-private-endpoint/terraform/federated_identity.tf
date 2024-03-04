resource "azuredevops_project" "ado_project" {
  name               = "ADO TF Federated Credential Example"
  visibility         = "private"
  version_control    = "Git"
  work_item_template = "Agile"
  description        = "Managed by Terraform"
}

resource "azurerm_user_assigned_identity" "umid" {
  location            = azurerm_resource_group.rg.location
  name                = "tf-federated-identity"
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azuredevops_serviceendpoint_azurerm" "service_endpoint" {
  project_id                             = azuredevops_project.ado_project.id
  service_endpoint_name                  = "example-federated-sc"
  description                            = "Managed by Terraform"
  service_endpoint_authentication_scheme = "WorkloadIdentityFederation"
  credentials {
    serviceprincipalid = azurerm_user_assigned_identity.umid.client_id
  }
  azurerm_spn_tenantid      = "3d49be6f-6e38-404b-bbd4-f61c1a2d25bf"
  azurerm_subscription_id   = "b2375b5f-8dab-4436-b87c-32bc7fdce5d0"
  azurerm_subscription_name = "Azure CXP FTA Internal Subscription CBELLEE"
}

resource "azurerm_federated_identity_credential" "federated_identity" {
  name                = "example-federated-credential"
  resource_group_name = azurerm_resource_group.rg.name
  parent_id           = azurerm_user_assigned_identity.umid.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azuredevops_serviceendpoint_azurerm.service_endpoint.workload_identity_federation_issuer
  subject             = azuredevops_serviceendpoint_azurerm.service_endpoint.workload_identity_federation_subject
}