resource azurerm_firewall_network_rule_collection "region1_az_network_rules" {
  name                = "network-rules"
  azure_firewall_name = azurerm_firewall.region1_az_firewall.name
  resource_group_name = azurerm_resource_group.region1_rg.name
  priority            = 1000
  action              = "Allow"

  rule {
    name = "allow time service"

    source_addresses = [
      var.region1.hubVnet.prefix,
      var.region1.spokeVnet.prefix,
    ]

    destination_ports = [
      "123",
    ]

    destination_addresses = [
      "*",
    ]

    protocols = [
      "UDP"
    ]
  }

  rule {
    name = "allow dns service"

    source_addresses = [
      var.region1.hubVnet.prefix,
      var.region1.spokeVnet.prefix,
    ]

    destination_ports = [
      "53",
    ]

    destination_addresses = [
      "*",
    ]

    protocols = [
      "TCP",
      "UDP"
    ]
  }

  rule {
    name = "allow tagged services"

    source_addresses = [
      var.region1.hubVnet.prefix,
      var.region1.spokeVnet.prefix,
    ]

    destination_ports = [
      "*",
    ]

    destination_addresses = [
      "AzureContainerRegistry",
      "MicrosoftContainerRegistry",
      "AzureActiveDirectory"
    ]

    protocols = [
      "TCP",
      "UDP"
    ]
  }
}

resource azurerm_firewall_application_rule_collection "region1_az_application_rules" {
  name                = "application-rules"
  azure_firewall_name = azurerm_firewall.region1_az_firewall.name
  resource_group_name = azurerm_resource_group.region1_rg.name
  priority            = 1000
  action              = "Allow"

  rule {
    name = "aks-services"

    source_addresses = [
      var.region1.hubVnet.prefix,
    ]

    target_fqdns = [
      "dc.services.visualstudio.com",
      "*.opinsights.azure.com",
      "*.oms.opinsights.azure.com",
      "*.microsoftonline.com",
      "*.monitoring.azure.com",
      "management.azure.com",
      "login.microsoftonline.com",
      "*.cdn.mscr.io",
      "mcr.microsoft.com",
      "*.data.mcr.microsoft.com",
      "acs-mirror.azureedge.net"
    ]

    protocol {
      port = "443"
      type = "Https"
    }

    protocol {
      port = "80"
      type = "Http"
    }
  }

  rule {
    name = "osupdates"

    source_addresses = [
      var.region1.hubVnet.prefix,
      var.region1.spokeVnet.prefix,
    ]

    target_fqdns = [
      "download.opensuse.org",
      "security.ubuntu.com",
      "packages.microsoft.com",
      "snapcraft.io"
    ]

    protocol {
      port = "443"
      type = "Https"
    }

    protocol {
      port = "80"
      type = "Http"
    }
  }
}

# region2
resource azurerm_firewall_network_rule_collection "region2_az_network_rules" {
  name                = "network-rules"
  azure_firewall_name = azurerm_firewall.region2_az_firewall.name
  resource_group_name = azurerm_resource_group.region2_rg.name
  priority            = 1000
  action              = "Allow"

  rule {
    name = "allow time service"

    source_addresses = [
      var.region2.hubVnet.prefix,
      var.region2.spokeVnet.prefix,
    ]

    destination_ports = [
      "123",
    ]

    destination_addresses = [
      "*",
    ]

    protocols = [
      "UDP"
    ]
  }

  rule {
    name = "allow dns service"

    source_addresses = [
      var.region2.hubVnet.prefix,
      var.region2.spokeVnet.prefix,
    ]

    destination_ports = [
      "53",
    ]

    destination_addresses = [
      "*",
    ]

    protocols = [
      "TCP",
      "UDP"
    ]
  }

  rule {
    name = "allow tagged services"

    source_addresses = [
      var.region2.hubVnet.prefix,
      var.region2.spokeVnet.prefix,
    ]

    destination_ports = [
      "*",
    ]

    destination_addresses = [
      "AzureContainerRegistry",
      "MicrosoftContainerRegistry",
      "AzureActiveDirectory"
    ]

    protocols = [
      "TCP",
      "UDP"
    ]
  }
}

resource azurerm_firewall_application_rule_collection "region2_az_application_rules" {
  name                = "application-rules"
  azure_firewall_name = azurerm_firewall.region2_az_firewall.name
  resource_group_name = azurerm_resource_group.region2_rg.name
  priority            = 1000
  action              = "Allow"

  rule {
    name = "aks-services"

    source_addresses = [
      var.region2.hubVnet.prefix,
      var.region2.spokeVnet.prefix,
    ]

    target_fqdns = [
      "dc.services.visualstudio.com",
      "*.opinsights.azure.com",
      "*.oms.opinsights.azure.com",
      "*.microsoftonline.com",
      "*.monitoring.azure.com",
      "management.azure.com",
      "login.microsoftonline.com",
      "*.cdn.mscr.io",
      "mcr.microsoft.com",
      "*.data.mcr.microsoft.com",
      "acs-mirror.azureedge.net"
    ]

    protocol {
      port = "443"
      type = "Https"
    }

    protocol {
      port = "80"
      type = "Http"
    }
  }

  rule {
    name = "osupdates"

    source_addresses = [
      var.region2.hubVnet.prefix,
      var.region2.spokeVnet.prefix,
    ]

    target_fqdns = [
      "download.opensuse.org",
      "security.ubuntu.com",
      "packages.microsoft.com",
      "snapcraft.io"
    ]

    protocol {
      port = "443"
      type = "Https"
    }

    protocol {
      port = "80"
      type = "Http"
    }
  }
}
