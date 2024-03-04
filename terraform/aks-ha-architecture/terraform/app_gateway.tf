locals {
  region1_app_gateway_name       = "${var.prefix}-${var.region1.locationShortName}-appgwy"
  region2_app_gateway_name       = "${var.prefix}-${var.region2.locationShortName}-appgwy"
  region1_app_gateway_pip_name   = "${var.prefix}-${var.region1.locationShortName}-appgwy-pip"
  region2_app_gateway_pip_name   = "${var.prefix}-${var.region2.locationShortName}-appgwy-pip"
  backend_address_pool_name      = "backend-pool"
  frontend_port_name             = "frontend-port"
  frontend_ip_configuration_name = "frontend-ip"
  http_setting_name              = "backend-htst"
  listener_name                  = "http-listener"
  request_routing_rule_name      = "req-routing-rule"
  redirect_configuration_name    = "redirect-cfg"
  frontend_port                  = 80
  frontend_protocol              = "Http"
  backend_port                   = 80
  backend_protocol               = "Http"
}

resource azurerm_public_ip "region1_app_gateway_pip" {
  name                = local.region1_app_gateway_pip_name
  location            = azurerm_resource_group.region1_rg.location
  resource_group_name = azurerm_resource_group.region1_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource azurerm_public_ip "region2_app_gateway_pip" {
  name                = local.region2_app_gateway_pip_name
  location            = azurerm_resource_group.region2_rg.location
  resource_group_name = azurerm_resource_group.region2_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource azurerm_application_gateway "region1_app_gateway" {
  name                = local.region1_app_gateway_name
  location            = azurerm_resource_group.region1_rg.location
  resource_group_name = azurerm_resource_group.region1_rg.name

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.region1_hub_subnet_2.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = local.frontend_port
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.region1_app_gateway_pip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = local.backend_port
    protocol              = local.backend_protocol
    request_timeout       = 1
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = local.frontend_protocol
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  tags = var.tags
}

resource azurerm_application_gateway "region2_app_gateway" {
  name                = local.region2_app_gateway_name
  location            = azurerm_resource_group.region2_rg.location
  resource_group_name = azurerm_resource_group.region2_rg.name

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.region2_hub_subnet_2.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = local.frontend_port
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.region2_app_gateway_pip.id
  }

  backend_address_pool {
    name = local.backend_address_pool_name
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = local.backend_port
    protocol              = local.backend_protocol
    request_timeout       = 1
  }

  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = local.frontend_protocol
  }

  request_routing_rule {
    name                       = local.request_routing_rule_name
    rule_type                  = "Basic"
    http_listener_name         = local.listener_name
    backend_address_pool_name  = local.backend_address_pool_name
    backend_http_settings_name = local.http_setting_name
  }

  tags = var.tags
}
