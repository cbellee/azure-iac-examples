param location string
param nsgName string

resource apimSubnetNsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-inbound-apim-mgmt'
        properties: {
          description: 'allow-inbound-apim-mgmt'
          direction: 'Inbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3443'
          sourceAddressPrefix: 'ApiManagement'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 1010
        }
      }
      {
        name: 'allow-outbound-apim-sql'
        properties: {
          description: 'allow-outbound-apim-sql'
          direction: 'Outbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Sql'
          access: 'Allow'
          priority: 1000
        }
      }
      {
        name: 'allow-outbound-apim-storage'
        properties: {
          description: 'allow-outbound-apim-storage'
          direction: 'Outbound'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRanges: [
            '80'
            '443'
          ]
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Storage'
          access: 'Allow'
          priority: 1010
        }
      }
    ]
  }
}

output nsgId string = apimSubnetNsg.id
