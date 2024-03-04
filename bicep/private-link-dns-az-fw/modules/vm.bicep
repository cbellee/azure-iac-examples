param location string
param name string
param subnetId string
param vmAdminUsername string
param vmAdminPasswordOrKey string
param vmSize string
param authenticationType string
param vmImage object
param osDiskSize int
param diskStorageAccountType string = 'Standard_LRS'

@allowed([
  'None'
  'ReadOnly'
  'ReadWrite'
])
param dataDiskCaching string = 'ReadOnly'
param dataDiskSize int
param storageAccount object
param nsgName string

var omsAgentForLinuxName = 'LogAnalytics'
var omsDependencyAgentForLinuxName = 'DependencyAgent'
var vmNicName = '${name}Nic'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${vmAdminUsername}/.ssh/authorized_keys'
        keyData: vmAdminPasswordOrKey
      }
    ]
  }
  provisionVMAgent: true
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  location: resourceGroup().location
  name: 'myLogs234234'
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
  }
}

resource vmNic 'Microsoft.Network/networkInterfaces@2020-04-01' = {
  name: vmNicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: name
      adminUsername: vmAdminUsername
      adminPassword: vmAdminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: {
        publisher: vmImage.Publisher
        offer: vmImage.Offer
        sku: vmImage.Sku
        version: 'latest'
      }
      osDisk: {
        name: '${name}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
        diskSizeGB: osDiskSize
        managedDisk: {
          storageAccountType: diskStorageAccountType
        }
      }
      dataDisks: [
        {
          caching: dataDiskCaching
          diskSizeGB: dataDiskSize
          lun: 0
          name: '${name}-DataDisk'
          createOption: 'Empty'
          managedDisk: {
            storageAccountType: diskStorageAccountType
          }
        }
      ]
      /*       copy: [
        {
          name: 'dataDisks'
          count: numDataDisks
          input: {
            caching: dataDiskCaching
            diskSizeGB: dataDiskSize
            lun: copyIndex('dataDisks')
            name: '${vmName}-DataDisk${copyIndex('dataDisks')}'
            createOption: 'Empty'
            managedDisk: {
              storageAccountType: diskStorageAccountType
            }
          }
        }
      ] */
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccount.properties.primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    vmNic
  ]
}

resource vmOmsAgentForLinux 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: '${vm.name}/${omsAgentForLinuxName}'
  location: location
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'OmsAgentForLinux'
    typeHandlerVersion: '1.12'
    settings: {
      workspaceId: logAnalyticsWorkspace.properties.customerId
      stopOnMultipleConnections: false
    }
    protectedSettings: {
      workspaceKey: listKeys(logAnalyticsWorkspace.id, logAnalyticsWorkspace.apiVersion).primarySharedKey
    }
  }
  dependsOn: [
    vm
  ]
}

resource vmOmsDependencyAgentForLinux 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: '${vm.name}/${omsDependencyAgentForLinuxName}'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: 'DependencyAgentLinux'
    typeHandlerVersion: '9.10'
    autoUpgradeMinorVersion: true
  }
  dependsOn: [
    vm
    vmOmsAgentForLinux
  ]
}

resource vmSubnetNsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowSshInbound'
        properties: {
          priority: 100
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '22'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource vmSubnetNsgInsights 'Microsoft.Network/networkSecurityGroups/providers/diagnosticSettings@2017-05-01-preview' = {
  name: '${nsgName}/Microsoft.Insights/default'
  location: location
  properties: {
    workspaceId: logAnalyticsWorkspace.id
    metrics: []
    logs: [
      {
        category: 'NetworkSecurityGroupEvent'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'NetworkSecurityGroupRuleCounter'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
  dependsOn: [
    vmSubnetNsg
  ]
}
