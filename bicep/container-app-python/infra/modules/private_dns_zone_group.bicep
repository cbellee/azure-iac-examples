param zoneConfigs array
param privateEndpointName string

resource private_dns_zone_group 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: '${privateEndpointName}/default'
  properties: {
    privateDnsZoneConfigs: zoneConfigs
  }
}
