param prefix string
param pfxCertificate string
param adminUserObjectId string
param containerPort string
param containerImageName string
param dnsZoneName string
param hostName string
param appServicePlanSku string
param subnets array
param vnetAddressPrefix string

var namingPrefix = '${prefix}-${uniqueString(resourceGroup().id)}'

resource userAssignedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  location: resourceGroup().location
  name: 'appGwyUserManagedId'
}

module vnetModule './modules/vnet.bicep' = {
  name: 'vnet'
  params: {
    prefix: namingPrefix
    subnets: subnets
    vnetAddressPrefix: vnetAddressPrefix
  }
}

module appServiceModule './modules/appService.bicep' = {
  name: 'deployAppService'
  params: {
    subnetId: vnetModule.outputs.appGatewaySubnetId
    containerPort: containerPort
    prefix: namingPrefix
    containerImageName: containerImageName
    sku: appServicePlanSku
  }
}

module keyVaultModule './modules/keyVault.bicep' = {
  name: 'deployKeyVault'
  params: {
    adminUserObjectId: adminUserObjectId
    certificateData: pfxCertificate
    userAssignedManagedIdentity: userAssignedManagedIdentity
    prefix: namingPrefix
  }
}

module appGatewayModule './modules/appGateway.bicep' = {
  name: 'appGwyDeploy'
  params: {
    userAssignedManagedIdentityId: userAssignedManagedIdentity.id
    prefix: namingPrefix
    gatewaySku: 'WAF_v2'
    subnetId: vnetModule.outputs.appGatewaySubnetId
    webAppHostName: appServiceModule.outputs.webAppHostName
    pfxCertSecretId: keyVaultModule.outputs.secretUri
    probePath: '/blockchain'
    frontEndHostName: '${hostName}.${dnsZoneName}'
  }
}

output appGatewayFrontEndIpAddress string = appGatewayModule.outputs.appGatewayFrontEndIpAddress
