param location string
param subnetId string
param vmSize string = 'Standard_D2_v3'
param computerName string
param dateTimeStamp string = utcNow()
param storageAccountName string
param domainName string
param userAssignedManagedIdentityResourceId string
param userAssignedManagedIdentityPrincipalId string
param pfxCertThumbprint string
param pfxCertSecretId string
param scriptUri string
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

var roleId = '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1' // 'Storage Blob Data Reader' RoleId
var suffix = uniqueString(resourceGroup().id)
var vmName = '${computerName}-${suffix}'
var nicName = 'web-vm-nic-1-${suffix}'

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

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: guid(resourceGroup().id, 'storageblobreader')
  properties: {
    roleDefinitionId: '/subscriptions/${subscription().subscriptionId}/providers/Microsoft.Authorization/roleDefinitions/${roleId}'
    principalId: userAssignedManagedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource windowsVm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  location: location
  name: vmName
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedManagedIdentityResourceId}': {}
    }
  }
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

resource vmKeyVaultExtension 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  name: 'KeyVaultForWindows'
  parent: windowsVm
  location: location
  properties: {
    forceUpdateTag: dateTimeStamp
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.Azure.KeyVault'
    type: 'KeyVaultForWindows'
    typeHandlerVersion: '1.0'
    settings: {
      secretsManagementSettings: {
        pollingIntervalInS: '3600'
        certificateStoreName: 'My'
        certificateStoreLocation: 'LocalMachine'
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
  parent: windowsVm
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
      commandToExecute: 'powershell.exe -ExecutionPolicy Unrestricted -File iis.ps1 -PfxThumbprint ${pfxCertThumbprint} -WebSiteName "Default Web Site" -DomainName ${domainName}'
    }
    protectedSettings: {
      managedIdentity: {
        object: userAssignedManagedIdentityPrincipalId
      }
    }
  }
}

output ipAddress string = vmNic.properties.ipConfigurations[0].properties.privateIPAddress
output hostName string = windowsVm.properties.osProfile.computerName
