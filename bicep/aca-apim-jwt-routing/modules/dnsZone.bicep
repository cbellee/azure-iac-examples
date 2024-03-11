param dnsZoneName string
param acaIlbIpAddress string
param acaEnvironmentDomainName string
param vnetName string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: acaEnvironmentDomainName
  location: 'global'
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-06-01' existing = {
  name: vnetName
}

resource dnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '*'
  parent: privateDnsZone
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: acaIlbIpAddress
      }
    ]
  }
}

resource dnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${dnsZoneName}-${vnet.name}-link'
  parent: privateDnsZone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}
