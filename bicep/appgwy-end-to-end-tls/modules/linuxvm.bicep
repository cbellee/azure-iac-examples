param location string
param subnetId string
param name string
param vmSize string = 'Standard_D2_v3'
param sshKey string
param adminUserName string
param scriptUri string
param storageAccountName string

@secure()
param pfxCertSecretId string

param dateTimeStamp string = utcNow()
param userAssignedManagedIdentityPrincipalId string
param userAssignedManagedIdentityResourceId string
param imageRef object = {
  offer: '0001-com-ubuntu-server-focal'
  publisher: 'Canonical'
  sku: '20_04-lts'
  version: 'latest'
}

var vmName = name
var suffix = uniqueString(resourceGroup().id)
var nicName = 'linux-vm-nic-1-${suffix}'
var roleId = '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1' // 'Storage Blob Data Reader' RoleId

resource storage 'Microsoft.Storage/storageAccounts@2021-06-01' existing = {
  name: storageAccountName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: guid(resourceGroup().id, 'storageblobreader')
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${roleId}'
    principalId: userAssignedManagedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

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
      adminUsername: adminUserName
      computerName: vmName
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
        patchSettings: {
          patchMode: 'AutomaticByPlatform'
        }
      }
    }
  }
}

resource vmKeyVaultExtension 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  name: 'KVVMExtensionForLinux'
  parent: vm
  location: location
  properties: {
    forceUpdateTag: dateTimeStamp
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.Azure.KeyVault'
    type: 'KVVMExtensionForLinux'
    typeHandlerVersion: '2.0'
    settings: {
      secretsManagementSettings: {
        pollingIntervalInS: '3600'
        certificateStoreLocation: '/var/lib/waagent/Microsoft.Azure.KeyVault'
        requireInitialSync: true
        observedCertificates: [
          pfxCertSecretId
        ]
        authenticationSettings: {
          msiEndpoint: 'http://169.254.169.254/metadata/identity'
          msiClientId: reference(userAssignedManagedIdentityResourceId, '2018-11-30').clientId
        }
      }
    }
  }
}

resource vmScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  location: location
  dependsOn: [
    vmKeyVaultExtension
  ]
  name: 'scriptext'
  parent: vm
  properties: {
    forceUpdateTag: dateTimeStamp
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    settings: {
      fileUris: [
        scriptUri
      ]
      commandToExecute: 'apache.sh'
    }
    protectedSettings: {
      managedIdentity: {
        object: userAssignedManagedIdentityPrincipalId
      }
    }
  }
}

output hostName string = vm.properties.osProfile.computerName
output ipAddress string = vmNic.properties.ipConfigurations[0].properties.privateIPAddress
