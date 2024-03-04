param hostName string
param zoneName string
param cname string

resource zone 'Microsoft.Network/dnsZones@2023-07-01-preview' existing = {
  name: zoneName
}

resource cnameRecord 'Microsoft.Network/dnsZones/CNAME@2023-07-01-preview' = {
  name: hostName
  parent: zone
  properties: {
    TTL: 300
    CNAMERecord: {
      cname: cname
    }
  }
}
