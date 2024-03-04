param dnsZoneName string
param hostName string
param appGatewayFrontEndIpAddress string

resource dnsZone 'Microsoft.Network/dnsZones@2018-05-01' existing = {
  name: dnsZoneName
}

resource dnsARecord 'Microsoft.Network/dnsZones/A@2018-05-01' = {
  name: '${dnsZone.name}/${hostName}'
  properties: {
    TTL: 3600
    ARecords: [
      {
        ipv4Address: appGatewayFrontEndIpAddress
      }
    ]
  }
}
