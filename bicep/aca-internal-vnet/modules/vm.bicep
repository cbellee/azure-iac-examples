param location string
param adminUserName string
param sshKey string
param vnetName string
param prefix string
param sku string = 'Standard_B1s'
param imageRef object = {
  publisher: 'Canonical'
  offer: 'UbuntuServer'
  sku: '18.04-LTS'
  version: 'latest'
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' existing = {
  name: vnetName
}

resource vm_nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: '${prefix}-linux-vm-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, vnet.properties.subnets[1].name)
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' = {
  name: '${prefix}-linux-vm'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: sku
    }
    storageProfile: {
      imageReference: imageRef
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vm_nic.id
        }
      ]
    }
    osProfile: {
      computerName: '${prefix}-linux-vm'
      adminUsername: adminUserName
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUserName}/.ssh/authorized_keys'
              keyData: sshKey
            }
          ]
        }
      }
    }
  }
}

output id string = vm.id
