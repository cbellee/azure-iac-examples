param domainName string
param location string
param storageAccountName string
param storageContainerUri string
param windowsScriptName string
param linuxScriptName string
param windowsBackendHostName string
param linuxBackendHostName string
param backendPort int
param frontendPort int
param dnsZoneResourceGroup string
param keyVaultName string
param frontEndHostName string
param publicPfxCertId string
param backendPemCertId string
param backendPfxThumbprint string
param trustedRootCertName string = 'trusted-root-cert'
param trustedRootCertId string 
param backendPfxCertId string
param windowsFrontendHostName string = 'iis.kainiindustries.net'
param linuxFrontendHostName string = 'apache.kainiindustries.net'
param sshKey string
param customData string

@secure()
param winVmPassword string
var base64CustomData = base64(customData)

resource userAssignedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  location: location
  name: 'kvMid'
}

module keyVaultAccessPolicy 'modules/keyVaultAccessPolicy.bicep' = {
  name: 'keyVaultAccessPolicyDeployment'
  params: {
    objectId: userAssignedManagedIdentity.properties.principalId
    keyVaultName: keyVaultName
  }
}

module networkSecurityGroupModule './modules/nsg.bicep' = {
  name: 'nsgDeployment'
  params: {
    location: location
  }
}

module vnetModule './modules/vnet.bicep' = {
  name: 'vnetDeployment'
  params: {
    location: location
  }
  dependsOn: [
    networkSecurityGroupModule
  ]
}

module bastionModule './modules/bastion.bicep' = {
  name: 'bastionDeployment'
  params: {
    location: location
    subnetId: vnetModule.outputs.subnetRefs[2].id
  }
}

module winVmModule './modules/winvm.bicep' = {
  name: 'winVmDeployment'
  params: {
    storageAccountName: storageAccountName
    computerName: 'win-vm-1'
    userAssignedManagedIdentityResourceId: userAssignedManagedIdentity.id
    userAssignedManagedIdentityPrincipalId: userAssignedManagedIdentity.properties.principalId
    pfxCertThumbprint: backendPfxThumbprint
    scriptUri: '${storageContainerUri}/${windowsScriptName}'
    pfxCertSecretId: backendPfxCertId
    domainName: frontEndHostName
    windowsOSVersion: '2016-Datacenter'
    adminPassword: winVmPassword
    adminUserName: 'localadmin'
    location: location
    subnetId: vnetModule.outputs.subnetRefs[1].id
    vmSize: 'Standard_D2_v3'
  }
}

module linuxVmModule 'modules/linuxvms.bicep' = {
  name: 'linuxDeployment'
  params: {
    vms: [
      'linux-vm-01'
      'linux-vm-02'
    ]
    pemCertId: backendPemCertId
    keyVaultId: resourceId('Microsoft.KeyVault/vaults', keyVaultName)
    scriptUri: '${storageContainerUri}/${linuxScriptName}'
    userAssignedManagedIdentityResourceId: userAssignedManagedIdentity.id
    userAssignedManagedIdentityPrincipalId: userAssignedManagedIdentity.properties.principalId
    location: location
    adminUserName: 'localadmin'
    sshKey: sshKey
    subnetId: vnetModule.outputs.subnetRefs[1].id
    vmSize: 'Standard_D2_v3'
    customData: base64CustomData
  }
}

module applicationGatewayModule './modules/appgateway.bicep' = {
  name: 'applicationGatewayDeployment'
  params: {
    userAssignedManagedIdentityResourceId: userAssignedManagedIdentity.id
    windowsBackendHostName: windowsBackendHostName
    linuxBackendHostName: linuxBackendHostName
    backendPort: backendPort
    linuxBackendIpAddresses: linuxVmModule.outputs.vms
    trustedRootCertName: trustedRootCertName
    trustedRootCertId: trustedRootCertId
    windowsBackendIpAddress: winVmModule.outputs.ipAddress
    linuxFrontEndHostName: linuxFrontendHostName
    windowsFrontendHostName: windowsFrontendHostName
    location: location
    publicPfxCertSecretId: publicPfxCertId
    frontendPort: frontendPort
    subnetId: vnetModule.outputs.subnetRefs[0].id
    maxCapacity: 10
    minCapacity: 1
    gatewaySku: 'WAF_v2'
  }
}

module appGwyApiPublicDnsRecord 'modules/publicdns.bicep' = {
  scope: resourceGroup(dnsZoneResourceGroup)
  name: 'deployAppGwyPublicDnsRecord'
  params: {
    zoneName: domainName
    ipAddress: applicationGatewayModule.outputs.appGatewayFrontEndIpAddress
    recordName: 'api'
  }
}
