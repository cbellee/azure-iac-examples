param location string
param sku string = 'Standard_DS1_v2'
param subnetId string
param userName string
param sshPublicKey string
param imageReference object = {
  publisher: 'Canonical'
  offer: '0001-com-ubuntu-server-jammy'
  sku: '22_04-lts-gen2'
  version: 'latest'
}

var suffix = uniqueString(resourceGroup().id)
var vmName = 'vm-${suffix}'
var nicName = 'vm-nic-${suffix}'

resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconf'
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

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: vmName
  location: location
  properties: {
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            primary: true
          }
        }
      ]
    }
    hardwareProfile: {
      vmSize: sku
    }
    storageProfile: {
      imageReference: imageReference
      osDisk: {
        createOption: 'FromImage'
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: userName
      linuxConfiguration: {
        disablePasswordAuthentication: true
        enableVMAgentPlatformUpdates: true
        ssh: {
          publicKeys: [
            {
              keyData: sshPublicKey
              path: '/home/${userName}/.ssh/authorized_keys'
            }
          ]
        }
      }
    }
  }
}
