param suffix string
param location string

resource workloadSubnetNsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'workload-subnet-nsg-${suffix}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-443-inbound'
        properties: {
          description: 'Allow AppGateway subnet inbound to vNet on port 443'
          protocol: 'Tcp'
          direction: 'Inbound'
          access: 'Allow'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '443'
          priority: 1000
          sourceAddressPrefix: '10.1.0.0/24'
          sourcePortRange: '*'
        }
      }
    ]
  }
}

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

resource bastionSubnetNsg 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
  name: 'bastion-subnet-nsg-${suffix}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHttpsInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowGatewayManagerInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'GatewayManager'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowLoadBalancerInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowBastionHostCommunicationInBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowSshRdpOutBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRanges: [
            '22'
            '3389'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowAzureCloudCommunicationOutBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowBastionHostCommunicationOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 120
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowGetSessionInformationOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRanges: [
            '80'
            '443'
          ]
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Outbound'
        }
      }
    ]
  }
}

output nsgs array = concat(array(appGatewaySubnetNsg.id))
