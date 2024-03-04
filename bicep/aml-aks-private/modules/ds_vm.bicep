@description('Username for Administrator Account')
param adminUsername string

param suffix string

@description('The name of you Virtual Machine.')
param vmName string

param subnetId string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Choose between CPU or GPU processing')
@allowed([
  'CPU-4GB'
  'CPU-7GB'
  'CPU-8GB'
  'CPU-14GB'
  'CPU-16GB'
  'GPU-56GB'
])
param cpu_gpu string = 'CPU-4GB'

param imageRef object = {
  publisher: 'microsoft-dsvm'
  offer: 'dsvm-win-2019'
  sku: 'server-2019'
  version: 'latest'
}

@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
@allowed([
  'sshPublicKey'
  'password'
])
param authenticationType string = 'password'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
param adminPasswordOrKey string

var networkInterfaceName = '${vmName}-${suffix}-nic'
var virtualMachineName = '${vmName}-${cpu_gpu}-${suffix}'
var osDiskType = 'StandardSSD_LRS'
var vmSize = {
  'CPU-4GB': 'Standard_B2s'
  'CPU-7GB': 'Standard_D2s_v3'
  'CPU-8GB': 'Standard_D2s_v3'
  'CPU-14GB': 'Standard_D4s_v3'
  'CPU-16GB': 'Standard_D4s_v3'
  'GPU-56GB': 'Standard_NC6_Promo'
}

var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2023-04-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2023-03-01' = {
  name: virtualMachineName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize[cpu_gpu]
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: imageRef
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
  }
}

output adminUsername string = adminUsername
output privateIp string = networkInterface.properties.ipConfigurations[0].properties.privateIPAddress
