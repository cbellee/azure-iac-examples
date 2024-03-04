param appGatewayNsgName string
param appGatewayPublicIpAddress string
param tags object

resource appGatewaySubnetNsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: appGatewayNsgName
  location: resourceGroup().location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'appgwy-v1'
        properties: {
          description: 'This rule is needed for application gateway probes to work'
          protocol: '*'
          destinationAddressPrefix: '*'
          sourcePortRange: '*'
          destinationPortRange: '65503-65534'
          sourceAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'appgwy-v2'
        properties: {
          description: 'This rule is needed for application gateway probes to work'
          protocol: '*'
          destinationAddressPrefix: '*'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 1010
          direction: 'Inbound'
        }
      }
      {
        name: 'appgwy-inbound-internet'
        properties: {
          description: 'This rule is needed for application gateway probes to work'
          protocol: 'Tcp'
          destinationAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationPortRange: ''
          destinationPortRanges: [
            '443'
          ]
          sourceAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 1020
          direction: 'Inbound'
        }
      }
    ]
  }
}


output nsgResourceIds array = concat(array(appGatewaySubnetNsg.id))
