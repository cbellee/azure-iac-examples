locals {
  app_gateway_name               = "${var.prefix}-appgwy"
  app_gateway_pip_name           = "${var.prefix}-appgwy-pip"
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

resource azurerm_public_ip "app_gateway_pip" {
  name                = local.app_gateway_pip_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource azurerm_application_gateway "app_gateway" {
  name                = local.app_gateway_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.subnet_1.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = local.frontend_port
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.app_gateway_pip.id
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
