param suffix string
param location string
param appGatewayPublicIpAddress string

resource appGatewaySubnetNsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'appGateway-subnet-nsg-${suffix}'
  location: location
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
        name: 'allow-inbound-app-gwy'
        properties: {
          description: 'allow-inbound-app-gwy'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3443'
          sourceAddressPrefix: appGatewayPublicIpAddress
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 1020
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

output nsgs array = concat(array(apimSubnetNsg.id),array(appGatewaySubnetNsg.id))
