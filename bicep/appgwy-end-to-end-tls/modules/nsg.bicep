param location string

var suffix = uniqueString(resourceGroup().id)

resource appGatewaySubnetNsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'ag-subnet-nsg-${suffix}'
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

resource vmSubnetNsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'vm-subnet-nsg-${suffix}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-rdp-inbound'
        properties: {
          description: 'allow inbound port 3389'
          protocol: '*'
          destinationAddressPrefix: '*'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 1100
          direction: 'Inbound'
        }
      }
      {
        name: 'allow-ssh-inbound'
        properties: {
          description: 'allow inbound port 22'
          protocol: '*'
          destinationAddressPrefix: '*'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 1200
          direction: 'Inbound'
        }
      }
      {
        name: 'allow-https-inbound'
        properties: {
          description: 'allow inbound port 443'
          protocol: '*'
          destinationAddressPrefix: '*'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
    ]
  }
}
