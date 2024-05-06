param zoneName string

resource aca_private_dns_zone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: zoneName
  location: 'global'
  properties: {}
}

output name string = zoneName
