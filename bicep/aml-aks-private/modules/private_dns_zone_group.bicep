param zoneConfigs array
param privateEndpointName string

resource private_dns_zone_group 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-04-01' = {
  name: '${privateEndpointName}/default'
  properties: {
    privateDnsZoneConfigs: zoneConfigs
  }
}
