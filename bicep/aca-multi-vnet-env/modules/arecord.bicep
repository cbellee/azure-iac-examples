param name string
param ipAddress string
param zoneName string

resource private_dns_zone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: zoneName
}

resource private_dns_record_set 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '*.${name}'
  parent: private_dns_zone
  properties: {
    ttl: 300
    aRecords: [
      {
        ipv4Address: ipAddress
      }
    ]
  }
}
