param location string
param nsgName string

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'BatchNodeManagement_1'
        properties: {
          protocol: 'Tcp'
          access: 'Allow'
          sourcePortRange: '*'
          destinationPortRange: '29877'
          sourceAddressPrefix: 'BatchNodeManagement'
          destinationAddressPrefix: 'VirtualNetwork'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'BatchNodeManagement_2'
        properties: {
          protocol: 'Tcp'
          access: 'Allow'
          sourcePortRange: '*'
          destinationPortRange: '29876'
          sourceAddressPrefix: 'BatchNodeManagement'
          destinationAddressPrefix: 'VirtualNetwork'
          priority: 1100
          direction: 'Inbound'
        }
      }
      {
        name: 'AzureMachineLearning'
        properties: {
          protocol: 'Tcp'
          access: 'Allow'
          sourcePortRange: '*'
          destinationPortRange: '44224'
          sourceAddressPrefix: 'AzureMachineLearning'
          destinationAddressPrefix: 'VirtualNetwork'
          priority: 1200
          direction: 'Inbound'
        }
      }

      {
        name: 'JupyterHub'
        properties: {
          priority: 1300
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '8000'
        }
      }
      {
        name: 'RStudioServer'
        properties: {
          priority: 1400
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '8787'
        }
      }
      {
        name: 'RDP'
        properties: {
          priority: 1500
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRange: '3389'
        }
      }
    ]
  }
}
