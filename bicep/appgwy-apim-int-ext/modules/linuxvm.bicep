param location string
param subnetId string
param suffix string
param vmSize string = 'Standard_D2_v3'
param adminPassword string
param adminUserName string
param imageRef object = {
  offer: '0001-com-ubuntu-server-focal'
  publisher: 'Canonical'
  sku: '20_04-lts'
  version: 'latest'
}
param customData string

var base64CustomData = base64(customData)
var vmName = 'linux-vm-${suffix}'
var nicName = 'linux-vm-nic-1-${suffix}'
var computerName = 'linux-vm-${substring(suffix, 0, 6)}'

resource vmNic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  location: location
  name: nicName
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

resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  location: location
  name: vmName
  properties: {
    storageProfile: {
      imageReference: imageRef
      osDisk: {
        createOption: 'FromImage'
      }
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vmNic.id
        }
      ]
    }
    osProfile: {
      customData: base64CustomData
      adminPassword: adminPassword
      adminUsername: adminUserName
      computerName: computerName
      linuxConfiguration: {
        disablePasswordAuthentication: false
        patchSettings: {
          patchMode: 'AutomaticByPlatform'
        }
      }
    }
  }
}
