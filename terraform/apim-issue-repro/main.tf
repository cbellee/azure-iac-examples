provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.location
}

resource "azurerm_virtual_network" "apim_vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  name                = "${var.vnet_name}-${substr(sha1(azurerm_resource_group.rg.id), 0, 8)}"
  address_space       = ["192.168.0.0/16"]
  location            = azurerm_resource_group.rg.location
  subnet {
    name           = "vm-subnet"
    address_prefix = "192.168.0.0/24"
  }

  subnet {
    name           = "apim-subnet"
    address_prefix = "192.168.1.0/24"
  }
}

resource "azurerm_key_vault" "kv" {
  name                        = "${var.key_vault_name}-${substr(sha1(azurerm_resource_group.rg.id), 0, 8)}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_api_management.apim.identity.0.principal_id

    certificate_permissions = [
      "Get",
      "Create",
      "List",
      "Update",
      "Import",
      "Delete",
    ]

    key_permissions = [
      "Get",
      "Create",
      "List",
      "Delete",
    ]

    secret_permissions = [
      "Get",
      "Set",
      "List",
      "Delete",
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    certificate_permissions = [
      "Get",
      "Create",
      "List",
      "Update",
      "Import",
      "Delete",
    ]

    key_permissions = [
      "Get",
      "Create",
      "List",
      "Delete",
    ]

    secret_permissions = [
      "Get",
      "Set",
      "List",
      "Delete",
    ]
  }
}

resource "azurerm_key_vault_certificate" "apim_cert" {
  name         = var.apim_cert_name
  key_vault_id = azurerm_key_vault.kv.id

  certificate {
    contents = filebase64("./certs/clientCert.pfx")
    password = var.apim_cert_password
  }

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = false
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }
  }
}

resource "azurerm_key_vault_certificate" "apim_cert_2" {
  name         = var.apim_cert_name_2
  key_vault_id = azurerm_key_vault.kv.id

  certificate {
    contents = filebase64("./certs/clientCert2.pfx")
    password = var.apim_cert_password
  }

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = false
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }
  }
}

resource "azurerm_api_management" "apim" {
  identity {
    type = "SystemAssigned"
  }
  name                 = "${var.apim_name}-${substr(sha1(azurerm_resource_group.rg.id), 0, 8)}"
  resource_group_name  = azurerm_resource_group.rg.name
  location             = azurerm_resource_group.rg.location
  virtual_network_type = "External"
  virtual_network_configuration {
    subnet_id = azurerm_virtual_network.apim_vnet.subnet.*.id[0]
  }
  publisher_name            = "Kaini Industries Inc."
  publisher_email           = var.publisher_email
  notification_sender_email = var.sender_email
  sku_name                  = "Premium_1"
  policy = [{
    xml_link    = null
    xml_content = <<XML
          <policies>
              <inbound>
                  <cors allow-credentials="true">
                      <allowed-origins>
                          <origin>https://developer.${var.domain_name}</origin>
                      </allowed-origins>
                      <allowed-methods preflight-result-max-age="300">
                          <method>*</method>
                      </allowed-methods>
                      <allowed-headers>
                          <header>*</header>
                      </allowed-headers>
                      <expose-headers>
                          <header>*</header>
                      </expose-headers>
                  </cors>
              </inbound>
              <backend>
                  <forward-request />
              </backend>
              <outbound>
              </outbound>
              <on-error>
              </on-error>
          </policies>
        XML
  }]
}

resource "azurerm_api_management_certificate" "apim-cert" {
  name                = azurerm_key_vault_certificate.apim_cert.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  key_vault_secret_id = azurerm_key_vault_certificate.apim_cert.secret_id
}

resource "azurerm_api_management_certificate" "apim-cert-2" {
  name                = azurerm_key_vault_certificate.apim_cert_2.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  key_vault_secret_id = azurerm_key_vault_certificate.apim_cert_2.secret_id
}

resource "azurerm_api_management_custom_domain" "apim_domain" {
  api_management_id = azurerm_api_management.apim.id
  management {
    host_name            = "management.apim.${var.domain_name}"
    certificate_password = var.apim_cert_password
    key_vault_id         = azurerm_api_management_certificate.apim-cert.key_vault_secret_id
  }
  developer_portal {
    host_name            = "developer.apim.${var.domain_name}"
    key_vault_id         = azurerm_api_management_certificate.apim-cert.key_vault_secret_id
    certificate_password = var.apim_cert_password
  }
  proxy {
    host_name            = "apim.${var.domain_name}"
    key_vault_id         = azurerm_api_management_certificate.apim-cert.key_vault_secret_id
    certificate_password = var.apim_cert_password
    default_ssl_binding  = true
  }
// uncomment to add an additional custom domain for the Api Management Proxy 
/*     proxy {
    host_name            = "proxy.internal.${var.domain_name}"
    key_vault_id         = azurerm_api_management_certificate.apim-cert.key_vault_secret_id
    certificate_password = var.apim_cert_password
  } */
}
