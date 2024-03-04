param zoneName string
param ipAddress string
param recordName string

resource publicDnsZone 'Microsoft.Network/dnsZones@2018-05-01' existing = {
  name: zoneName
}

resource appGwyPublicDnsRecord 'Microsoft.Network/dnsZones/A@2018-05-01' = {
  parent: publicDnsZone
  name: recordName
  properties: {
    ARecords: [
      {
        ipv4Address: ipAddress
      }
    ]
    TTL: 3600
  }
}
