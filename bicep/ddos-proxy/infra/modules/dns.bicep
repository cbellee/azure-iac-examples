param appGatewayIpAddress string
param dnsZoneName string = 'kainiindustries.net'
param recordName string = 'myapp'

resource dns 'Microsoft.Network/dnszones@2015-05-04-preview' existing = {
  name: dnsZoneName
}

resource arecord 'Microsoft.Network/dnsZones/A@2018-05-01' = {
  parent: dns
  name: recordName
  properties: {
    TTL: 3600
    ARecords: [
      {
        ipv4Address: appGatewayIpAddress
      }
    ]
  }
}
