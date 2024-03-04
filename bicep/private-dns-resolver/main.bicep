@description('name of the new virtual network where DNS resolver will be created')
param resolverVnetName string = 'hub-vnet'

@description('the IP address space for the resolver virtual network')
param resolverVnetAddressSpace string = '10.0.0.0/16'

param sshKey string

@description('name of the dns private resolver')
param dnsResolverName string = 'dnsResolver'

@description('the location for resolver VNET and dns private resolver - Azure DNS Private Resolver available in specific region, refer the documenation to select the supported region for this deployment. For more information https://docs.microsoft.com/azure/dns/dns-private-resolver-overview#regional-availability')
@allowed([
  'australiaeast'
  'uksouth'
  'northeurope'
  'southcentralus'
  'westus3'
  'eastus'
  'northcentralus'
  'westcentralus'
  'eastus2'
  'westeurope'
  'centralus'
  'canadacentral'
  'brazilsouth'
  'francecentral'
  'swedencentral'
  'switzerlandnorth'
  'eastasia'
  'southeastasia'
  'japaneast'
  'koreacentral'
  'southafricanorth'
])
param location string

@description('name of the subnet that will be used for private resolver inbound endpoint')
param inboundSubnet string = 'inbound-dns-resolver-subnet'

@description('the inbound endpoint subnet address space')
param inboundAddressPrefix string = '10.0.101.0/28'

@description('name of the subnet that will be used for private resolver outbound endpoint')
param outboundSubnet string = 'outbound-dns-resolver-subnet'

@description('the outbound endpoint subnet address space')
param outboundAddressPrefix string = '10.0.101.16/28'

@description('name of the subnet that will be used for private resolver outbound endpoint')
param gatewaySubnet string = 'GatewaySubnet'

@description('the outbound endpoint subnet address space')
param gatewayAddressPrefix string = '10.0.100.0/24'

@description('name of the vnet link that links outbound endpoint with forwarding rule set')
param resolvervnetlink string = 'vnetlink'

@description('name of the forwarding ruleset')
param forwardingRulesetName string = 'forwardingRule'

@description('name of the forwarding rule name')
param forwardingRuleName string = 'internal-kainiindustries-net'

param vpnGatewayName string = 's2s-vpn-gateway'

param localNetworkGatewayName string = 'local-vpn-gateway'

param localGatewayPublicIpAddress string

param publicIpAddressName string = 'vpn-pip'

param vpnSharedKey string

param VMSubnet string = 'vm-subnet'

param VMSubnetAddressPrefix string = '10.0.102.0/24'

param localAddressPrefixes array = [
  '192.168.88.0/24'
]

param PrivateLinkSubnet string = 'privatelink-subnet'

param PrivateLinkSubnetAddressPrefix string = '10.0.103.0/24'

param vmPrivateDnsZoneName string = 'azure.kainiindustries.net'

param onPremDnsServerIpAddress string = '192.168.88.1'

@description('the target domain name for the forwarding ruleset')
param DomainName string = 'internal.kainiindustries.net.'

@description('the list of target DNS servers ip address and the port number for conditional forwarding')
param targetDNS array = [
  {
    ipaddress: onPremDnsServerIpAddress
    port: 53
  }
]

resource resolverVnet 'Microsoft.Network/virtualNetworks@2022-01-01' = {
  name: resolverVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        resolverVnetAddressSpace
      ]
    }
    enableDdosProtection: false
    enableVmProtection: false
    subnets: [
      {
        name: gatewaySubnet
        properties: {
          addressPrefix: gatewayAddressPrefix
        }
      }
      {
        name: inboundSubnet
        properties: {
          addressPrefix: inboundAddressPrefix
          delegations: [
            {
              name: 'inbound-dnsResolver-delegation'
              properties: {
                serviceName: 'Microsoft.Network/dnsResolvers'
              }
            }
          ]
        }
      }
      {
        name: outboundSubnet
        properties: {
          addressPrefix: outboundAddressPrefix
          delegations: [
            {
              name: 'outbound-dnsResolver-delegation'
              properties: {
                serviceName: 'Microsoft.Network/dnsResolvers'
              }
            }
          ]
        }
      }
      {
        name: VMSubnet
        properties: {
          addressPrefix: VMSubnetAddressPrefix
        }
      }
      {
        name: PrivateLinkSubnet
        properties: {
          addressPrefix: PrivateLinkSubnetAddressPrefix
        }
      }
    ]
  }
}

resource vpnPublicIpAddress 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: publicIpAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource vmPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: vmPrivateDnsZoneName
  location: 'global'
}

resource vmPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'vm-private-dns-zone-link'
  parent: vmPrivateDnsZone
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: resolverVnet.id
    }
  }
}

module linuxVM 'modules/linuxvm.bicep' = {
  name: 'linux-vm-module'
  params: {
    name: 'linux-vm-01'
    location: location
    adminUserName: 'localadmin'
    sshKey: sshKey
    subnetId: '${resolverVnet.id}/subnets/${VMSubnet}'
  }
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2022-05-01' = {
  name: vpnGatewayName
  location: location
  properties: {
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
    vpnGatewayGeneration: 'Generation1'
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
    }
    ipConfigurations: [
      {
        name: 'vpn-config'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: vpnPublicIpAddress.id
          }
          subnet: {
            id: '${resolverVnet.id}/subnets/${gatewaySubnet}'
          }
        }
      }
    ]
  }
}

resource localNetworkGateway 'Microsoft.Network/localNetworkGateways@2022-05-01' = {
  name: localNetworkGatewayName
  location: location
  properties: {
    localNetworkAddressSpace: {
      addressPrefixes: localAddressPrefixes
    }
    gatewayIpAddress: localGatewayPublicIpAddress
  }
}

resource vpnCxn 'Microsoft.Network/connections@2022-05-01' = {
  name: 's2s-vpn-cxn'
  location: location
  properties: {
    connectionType: 'IPsec'
    routingWeight: 10
    sharedKey: vpnSharedKey
    virtualNetworkGateway1: {
      id: vpnGateway.id
    }
    localNetworkGateway2: {
      id: localNetworkGateway.id
    }
  }
}

resource resolver 'Microsoft.Network/dnsResolvers@2022-07-01' = {
  name: dnsResolverName
  location: location
  properties: {
    virtualNetwork: {
      id: resolverVnet.id
    }
  }
}

resource inEndpoint 'Microsoft.Network/dnsResolvers/inboundEndpoints@2022-07-01' = {
  parent: resolver
  name: inboundSubnet
  location: location
  properties: {
    ipConfigurations: [
      {
        privateIpAllocationMethod: 'Dynamic'
        subnet: {
          id: '${resolverVnet.id}/subnets/${inboundSubnet}'
        }
      }
    ]
  }
}

resource outEndpoint 'Microsoft.Network/dnsResolvers/outboundEndpoints@2022-07-01' = {
  parent: resolver
  name: outboundSubnet
  location: location
  properties: {
    subnet: {
      id: '${resolverVnet.id}/subnets/${outboundSubnet}'
    }
  }
}

resource fwruleSet 'Microsoft.Network/dnsForwardingRulesets@2022-07-01' = {
  name: forwardingRulesetName
  location: location
  properties: {
    dnsResolverOutboundEndpoints: [
      {
        id: outEndpoint.id
      }
    ]
  }
}

resource resolverLink 'Microsoft.Network/dnsForwardingRulesets/virtualNetworkLinks@2022-07-01' = {
  parent: fwruleSet
  name: resolvervnetlink
  properties: {
    virtualNetwork: {
      id: resolverVnet.id
    }
  }
}

resource fwRules 'Microsoft.Network/dnsForwardingRulesets/forwardingRules@2022-07-01' = {
  parent: fwruleSet
  name: forwardingRuleName
  properties: {
    domainName: DomainName
    targetDnsServers: targetDNS
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  kind: 'StorageV2'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  name: uniqueString('stor${resourceGroup().id}')
}

resource storageBlobPrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: 'storage-blob-private-endpoint'
  location: location
  properties: {
    subnet: {
      id: '${resolverVnet.id}/subnets/${PrivateLinkSubnet}'
    }
    privateLinkServiceConnections: [
      {
        name: 'storage-blob-plink'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource storageFilePrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: 'storage-file-private-endpoint'
  location: location
  properties: {
    subnet: {
      id: '${resolverVnet.id}/subnets/${PrivateLinkSubnet}'
    }
    privateLinkServiceConnections: [
      {
        name: 'storage-file-plink'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'file'
          ]
        }
      }
    ]
  }
}

resource storageTablePrivateEndpoint 'Microsoft.Network/privateEndpoints@2022-01-01' = {
  name: 'storage-table-private-endpoint'
  location: location
  properties: {
    subnet: {
      id: '${resolverVnet.id}/subnets/${PrivateLinkSubnet}'
    }
    privateLinkServiceConnections: [
      {
        name: 'storage-table-plink'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'table'
          ]
        }
      }
    ]
  }
}

resource storageBlobPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.${az.environment().suffixes.storage}'
  location: 'global'
}

resource storageFilePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.file.${az.environment().suffixes.storage}'
  location: 'global'
}

resource storageTablePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.table.${az.environment().suffixes.storage}'
  location: 'global'
}

resource storageBlobPrivateDNSZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-01-01' = {
  name: '${storageBlobPrivateEndpoint.name}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-blob-storage'
        properties: {
          privateDnsZoneId: storageBlobPrivateDnsZone.id
        }
      }
    ]
  }
}

resource storageFilePrivateDNSZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-01-01' = {
  name: '${storageFilePrivateEndpoint.name}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-file-storage'
        properties: {
          privateDnsZoneId: storageFilePrivateDnsZone.id
        }
      }
    ]
  }
}

resource storageTablePrivateDNSZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2022-01-01' = {
  name: '${storageTablePrivateEndpoint.name}/default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-table-storage'
        properties: {
          privateDnsZoneId: storageTablePrivateDnsZone.id
        }
      }
    ]
  }
}

resource storageBlobPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'blob-storage-dns-zone-link'
  parent: storageBlobPrivateDnsZone
  location: 'global'
  properties: {
    virtualNetwork: {
      id: resolverVnet.id
    }
    registrationEnabled: false
  }
}

resource storageFilePrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'file-storage-dns-zone-link'
  parent: storageFilePrivateDnsZone
  location: 'global'
  properties: {
    virtualNetwork: {
      id: resolverVnet.id
    }
    registrationEnabled: false
  }
}

resource storageTablePrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'table-storage-dns-zone-link'
  parent: storageTablePrivateDnsZone
  location: 'global'
  properties: {
    virtualNetwork: {
      id: resolverVnet.id
    }
    registrationEnabled: false
  }
}
