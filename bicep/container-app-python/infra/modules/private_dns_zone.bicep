@description('private dns zone name')
param privateDnsZoneName string

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: privateDnsZoneName
  location: 'global'
}

output dnsZoneName string = privateDnsZone.name
output dnsZoneId string = privateDnsZone.id
