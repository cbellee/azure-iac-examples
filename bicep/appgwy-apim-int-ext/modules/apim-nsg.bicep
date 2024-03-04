param suffix string
param location string

resource apimSubnetNsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'apim-subnet-nsg-${suffix}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-inbound-apim-mgmt'
        properties: {
          description: 'allow-inbound-apim-mgmt'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3443'
          sourceAddressPrefix: 'ApiManagement'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 1010
          direction: 'Inbound'
        }
      }
      {
        name: 'allow-outbound-apim-sql'
        properties: {
          description: 'allow-outbound-apim-sql'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Sql'
          access: 'Allow'
          priority: 1000
          direction: 'Outbound'
        }
      }
      {
        name: 'allow-outbound-apim-storage'
        properties: {
          description: 'allow-outbound-apim-storage'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: ''
          destinationPortRanges: [
            '80'
            '443'
          ]
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Storage'
          access: 'Allow'
          priority: 1010
          direction: 'Outbound'
        }
      }
    ]
  }
}
