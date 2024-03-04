param zoneName string
param recordName string
param ipAddress string

resource zone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: zoneName
}

resource dns_a_record 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: recordName
  parent: zone
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: ipAddress
      }
    ]
  }
}
