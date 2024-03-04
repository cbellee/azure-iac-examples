param zoneName string
param tags object

resource publicDnsZone 'Microsoft.Network/dnsZones@2018-05-01' = {
  location: 'global'
  name: zoneName
  properties: {
    zoneType: 'Public'
  }
  tags: tags
}

output dnsZoneName string = publicDnsZone.name
