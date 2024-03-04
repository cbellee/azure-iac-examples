param location string
param subnetId string
param suffix string
param vmSize string = 'Standard_D2_v3'
param adminPassword string
param adminUserName string
@allowed([
  '2008-R2-SP1'
  '2012-Datacenter'
  '2012-R2-Datacenter'
  '2016-Nano-Server'
  '2016-Datacenter-with-Containers'
  '2016-Datacenter'
  '2019-Datacenter'
])

@description('The Windows version for the VM. This will pick a fully patched image of this given Windows version.')
param windowsOSVersion string = '2019-Datacenter'

var vmName = 'win-vm-${suffix}'
var nicName = 'win-vm-nic-1-${suffix}'
var computerName = 'winvm1'

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

resource windowsVm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  location: location
  name: vmName
  properties: {
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: windowsOSVersion
        version: 'latest'
      }
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
      adminPassword: adminPassword
      adminUsername: adminUserName
      computerName: computerName
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
      }
    }
  }
}
