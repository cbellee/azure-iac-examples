param zoneName string
param afdEndpointFqdn string

resource publicDnsZone 'Microsoft.Network/dnsZones@2023-07-01-preview' existing = {
  name: zoneName
}

resource dnsCNAMERecord 'Microsoft.Network/dnsZones/CNAME@2023-07-01-preview' = {
  name: 'gateway'
  parent: publicDnsZone
  properties: {
    TTL: 3600
    CNAMERecord: {
      cname: afdEndpointFqdn
    }
  }
}
