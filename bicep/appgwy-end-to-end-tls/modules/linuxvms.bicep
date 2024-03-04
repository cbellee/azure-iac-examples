param location string
param subnetId string
param vms array = [
  'linux-vm-01'
  'linux-vm-02'
]
param vmSize string = 'Standard_D2_v3'
param sshKey string
param adminUserName string
param scriptUri string
param pemCertId string
param customData string
param keyVaultId string
param dateTimeStamp string = utcNow()
param userAssignedManagedIdentityPrincipalId string
param userAssignedManagedIdentityResourceId string
param imageRef object = {
  offer: '0001-com-ubuntu-server-focal'
  publisher: 'Canonical'
  sku: '20_04-lts'
  version: 'latest'
}

var roleId = '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1' // 'Storage Blob Data Reader' RoleId

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: guid(resourceGroup().id, 'storageblobreader')
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${roleId}'
    principalId: userAssignedManagedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource vmNic 'Microsoft.Network/networkInterfaces@2021-02-01' = [for vm in vms: {
  location: location
  name: '${vm}-nic-01'
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
}]

resource vmInstance 'Microsoft.Compute/virtualMachines@2021-03-01' = [for (vm, i) in vms: {
  location: location
  name: vm
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedManagedIdentityResourceId}': {}
    }
  }
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
          id: vmNic[i].id
        }
      ]
    }
    osProfile: {
      adminUsername: adminUserName
      computerName: vm
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
      customData: customData
      secrets: [
        {
          sourceVault: {
            id: keyVaultId
          }
          vaultCertificates: [
            {
              certificateUrl: pemCertId
            }
          ]
        }
      ]
    }
  }
}]

/* resource vmKeyVaultExtension 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = [for (vm, i) in vms: {
  name: 'KeyVaultForLinux'
  parent: vmInstance[i]
  location: location
  properties: {
    forceUpdateTag: dateTimeStamp
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    publisher: 'Microsoft.Azure.KeyVault'
    type: 'KeyVaultForLinux'
    typeHandlerVersion: '2.0'
    settings: {
      secretsManagementSettings: {
        pollingIntervalInS: '3600'
        certificateStoreLocation: '/var/lib/waagent/Microsoft.Azure.KeyVault'
        requireInitialSync: true
        observedCertificates: [
          pemCertId
        ]
        authenticationSettings: {
          msiEndpoint: 'http://169.254.169.254/metadata/identity'
          msiClientId: reference(userAssignedManagedIdentityResourceId, '2018-11-30').clientId
        }
      }
    }
  }
}]

resource vmScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = [for (vm, i) in vms: {
  location: location
  dependsOn: [
    vmKeyVaultExtension
  ]
  name: 'linuxCustomScriptExtension'
  parent: vmInstance[i]
  properties: {
    forceUpdateTag: dateTimeStamp
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    settings: {
      fileUris: [
        scriptUri
      ]
      commandToExecute: 'sh apache.sh'
    }
    protectedSettings: {
      managedIdentity: {
        object: userAssignedManagedIdentityPrincipalId
      }
    }
  }
}] */

output vms array = [for (vm, i) in vms: {
  hostName: vmInstance[i].properties.osProfile.computerName
  ipAddress: vmNic[i].properties.ipConfigurations[0].properties.privateIPAddress
}]
