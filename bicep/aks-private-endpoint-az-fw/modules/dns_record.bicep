@description('private DNS zone name')
param privateDnsZoneName string

@description('private endpoint Nic ipConfiguration array resource id')
param privateLinkNicIpConfig object

resource privateDnsZoneName_privateLinkNicIpConfig_properties_privateLinkConnectionProperties_fqdns_0 'Microsoft.Network/privateDnsZones/A@2018-09-01' = [for i in range(0, length(privateLinkNicIpConfig.properties.privateLinkConnectionProperties.fqdns)): {
  name: '${privateDnsZoneName}/${split(privateLinkNicIpConfig.properties.privateLinkConnectionProperties.fqdns[i], '.')[0]}'
  properties: {
    aRecords: concat(json('[{"ipv4Address":"${privateLinkNicIpConfig.properties.privateIPAddress}"}]'))
    ttl: 3600
  }
}]
