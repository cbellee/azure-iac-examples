param privateDnsZoneName string
param gatewayARecordName string
param aksNodeResourceGroup string
param albName string

resource dnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
}

resource alb 'Microsoft.Network/loadBalancers@2023-02-01' existing = {
  name: albName
  scope: resourceGroup(aksNodeResourceGroup)
}

resource aRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: dnsZone
  name: gatewayARecordName
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: alb.properties.frontendIPConfigurations[0].properties.privateIPAddress
      }
    ]
  }
}

output ilbIpAddress string = aRecord.properties.aRecords[0].ipv4Address
