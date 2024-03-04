param privateDnsName string
param vnetName string
param vnetResourceGroupName string

var separatedDnsName = split(privateDnsName, '.')
var dnsZoneName = '${separatedDnsName[1]}.${separatedDnsName[2]}.${separatedDnsName[3]}.${separatedDnsName[4]}.${separatedDnsName[5]}'

resource dnsZone 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${dnsZoneName}/${vnetName}'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: resourceId(vnetResourceGroupName, 'Microsoft.Network/virtualNetworks', vnetName)
    }
    registrationEnabled: false
  }
}
