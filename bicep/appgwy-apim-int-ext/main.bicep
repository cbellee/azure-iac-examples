param domainName string
param tags object
param location string
param cert object
param rootCert object
param winVmPassword string
param functionAppId string
param vNets array
param sqlAdminUserPassword string
param sqlAdminUserName string
param sqlDbName string
param adminObjectId string

var privateDomainName = 'internal.${domainName}'
var suffix = uniqueString(resourceGroup().id)
var keyVaultName = 'kv-${suffix}'
var dbCxnString = 'server=${sqlServerAndDb.outputs.sqlServerFQDN};user id=${sqlAdminUserName};password=${sqlAdminUserPassword};port=1433;database=${sqlServerAndDb.outputs.dbName}'
var azSeparatedAddressprefix = split(vNets[0].subnets[2].addressPrefix, '.')
var appGwySeparatedAddressprefix = split(vNets[0].subnets[0].addressPrefix, '.')
var azFirewallPrivateIpAddress = '${azSeparatedAddressprefix[0]}.${azSeparatedAddressprefix[1]}.${azSeparatedAddressprefix[2]}.4'
var appGwyPrivateIpAddress = '${appGwySeparatedAddressprefix[0]}.${appGwySeparatedAddressprefix[1]}.${appGwySeparatedAddressprefix[2]}.200'

module azMonitorModule './modules/azmon.bicep' = {
  name: 'azureMonitorDeployment'
  params: {
    suffix: suffix
  }
}

module udrModule './modules/udr.bicep' = {
  name: 'udrDeployment'
  params: {
    suffix: suffix
    azureFirewallPrivateIpAddress: azFirewallPrivateIpAddress
  }
}

module nsgModule './modules/nsg.bicep' = {
  name: 'nsgDeployment'
  params: {
    location: location
    appGatewayPublicIpAddress: '1.1.1.1'
    suffix: suffix
  }
}

// Virtual Networks
module vNetsModule './modules/vnets.bicep' = [for (item, i) in vNets: {
  name: 'module-vnet-${i}'
  scope: resourceGroup(resourceGroup().name)
  params: {
    suffix: suffix
    location: location
    vNet: item
    tags: tags
  }
  dependsOn: [
    udrModule
    nsgModule
  ]
}]

// Virtual Network Peering
module peeringModule './modules/peering.bicep' = {
  name: 'module-peering'
  scope: resourceGroup(resourceGroup().name)
  params: {
    suffix: suffix
    vNets: vNets
    isGatewayDeployed: false
  }
  dependsOn: [
    vNetsModule
  ]
}

// KeyVault
module keyvault 'modules/keyvault.bicep' = {
  name: 'module-keyvault'
  params: {
    location: location
    name: keyVaultName
    tenantId: tenant().tenantId
  }
}

// SQL Server & DB
module sqlServerAndDb 'modules/azure-sql-db.bicep' = {
  name: 'module-sqlDb'
  params: {
    location: location
    tags: tags
    suffix: suffix
    sqlAdminUserPassword: sqlAdminUserPassword
    sqlAdminUserName: sqlAdminUserName
    subnetId: vNetsModule[1].outputs.subnetRefs[4].id
    sqlDbName: 'todosDb'
  }
}

// Azure Firewall
module azureFirewallModule './modules/azfirewall.bicep' = {
  name: 'azureFirewallDeployment'
  params: {
    suffix: suffix
    location: location
    retentionInDays: 7
    workspaceId: azMonitorModule.outputs.workspaceId
    firewallSubnetRef: vNetsModule[0].outputs.subnetRefs[2].id
    sourceAddressRangePrefix: [
      '10.0.0.0/8'
      '192.168.88.0/24'
    ]
  }
}

// Azure Bastion
module bastionModule './modules/bastion.bicep' = {
  dependsOn: [
    azureFirewallModule
  ]
  name: 'bastionDeployment'
  params: {
    location: location
    subnetId: vNetsModule[0].outputs.subnetRefs[3].id
    suffix: suffix
  }
}

// Windows VM
module winVmModule './modules/winvm.bicep' = {
  dependsOn: [
    bastionModule
  ]
  name: 'winVmDeployment'
  params: {
    windowsOSVersion: '2016-Datacenter'
    adminPassword: winVmPassword
    adminUserName: 'localadmin'
    location: location
    subnetId: vNetsModule[0].outputs.subnetRefs[1].id
    suffix: suffix
    vmSize: 'Standard_D2_v3'
  }
}

resource secret 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  name: '${keyVaultName}/dbCxnString'
  properties: {
    value: dbCxnString
  }
}

// Function App
module funcAppModule './modules/funcapp.bicep' = {
  name: 'funcAppDeployment'
  params: {
    location: location
    secretUri: secret.properties.secretUri
    vnetIntegrationSubnetId: vNetsModule[1].outputs.subnetRefs[4].id
    apimSubnetId: vNetsModule[0].outputs.subnetRefs[4].id
    planSku: 'ElasticPremium'
    planSkuCode: 'EP1'
    planKind: 'elastic'
    suffix: suffix
    apimManagedIdentityPrincipalId: apiManagementModule.outputs.apimManagedIdentityPrincipalId
    appId: functionAppId
    tags: tags
  }
}

// Key Vault Policies
module keyvaultPolicies 'modules/keyvault_policy.bicep' = {
  name: 'deployKeyVaultPolicies'
  params: {
    accessPolicies: [
      {
        permissions: {
          keys: [
            'all'
          ]
          secrets: [
            'all'
          ]
          certificates: [
            'all'
          ]
        }
        tenantId: tenant().tenantId
        objectId: adminObjectId
      }
      {
        permissions: {
          secrets: [
            'get'
            'list'
          ]
          keys: []
          certificates: []
        }
        tenantId: tenant().tenantId
        objectId: funcAppModule.outputs.principalId
      }
    ]
    keyVaultName: keyvault.outputs.keyVaultName
  }
}

// Private DNS zones
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location: 'global'
  tags: tags
  name: privateDomainName
  properties: {}
}

// APIM
module apiManagementModule './modules/apim.bicep' = {
  dependsOn: [
    azMonitorModule
    azureFirewallModule
  ]
  name: 'apimDeployment'
  params: {
    tags: tags
    location: location
    retentionInDays: 30
    workspaceId: azMonitorModule.outputs.workspaceId
    privateDnsZoneName: privateDnsZone.name
    hubVnetId: vNetsModule[0].outputs.vnetRef
    spokeVnetId: vNetsModule[1].outputs.vnetRef
    apimSku: {
      name: 'Developer'
      capacity: 1
    }
    deployCertificates: true
    proxyHostName: 'proxy.${privateDomainName}'
    portalHostName: 'portal.${privateDomainName}'
    managementHostName: 'management.${privateDomainName}'
    certificate: cert.CertValue
    certificatePassword: cert.CertPassword
    subnetId: vNetsModule[0].outputs.subnetRefs[4].id
  }
}

/* module apiModule './modules/api.bicep' = {
  dependsOn: [
    apiManagementModule
  ]
  name: 'apiDeployment'
  params: {
    apimName: apiManagementModule.outputs.apimName
    apiName: 'todo-api'
    functionUri: funcAppModule.outputs.funcAppUrl
  }
} */

// Application Gateway
module applicationGatewayModule './modules/appgateway.bicep' = {
  dependsOn: [
    azMonitorModule
    privateDnsZone
  ]
  name: 'applicationGatewayDeployment'
  params: {
    suffix: suffix
    location: location
    privateDnsZoneName: privateDomainName
    workspaceId: azMonitorModule.outputs.workspaceId
    apimGatewaySslCertPassword: cert.CertPassword
    frontEndPort: 443
    internalFrontendPort: 8080
    retentionInDays: 7
    externalProxyHostName: 'api.${domainName}'
    externalPortalHostName: 'portal.${domainName}'
    externalManagementHostName: 'management.${domainName}'
    internalProxyHostName: 'proxy.${privateDomainName}'
    internalPortalHostName: 'portal.${privateDomainName}'
    internalManagementHostName: 'management.${privateDomainName}'
    rootSslCert: rootCert.CertValue
    apimGatewaySslCert: cert.CertValue
    apimPrivateIpAddress: appGwyPrivateIpAddress
    gatewaySku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: '1'
    }
    requestTimeOut: 180
    skuName: 'Standard'
    subnetId: vNetsModule[0].outputs.subnetRefs[0].id
  }
}

// NSG Update
module networkSecurityGroupUpdateModule './modules/nsg.bicep' = {
  name: 'nsgUpdateDeployment'
  params: {
    location: location
    suffix: suffix
    appGatewayPublicIpAddress: applicationGatewayModule.outputs.appGwyPublicIpAddress
  }
}

// Azure Public DNS records
module appGwyApiPublicDnsRecord 'modules/publicdns.bicep' = {
  scope: resourceGroup('external-dns-zones-rg')
  name: 'deployAppGwyPublicDnsRecord'
  params: {
    zoneName: domainName
    ipAddress: applicationGatewayModule.outputs.appGwyPublicIpAddress
    recordName: 'api'
  }
}

module appGwyApimPortalPublicDnsRecord 'modules/publicdns.bicep' = {
  scope: resourceGroup('external-dns-zones-rg')
  name: 'deployAppGwyApimPortalPublicDnsRecord'
  params: {
    zoneName: domainName
    ipAddress: applicationGatewayModule.outputs.appGwyPublicIpAddress
    recordName: 'portal'
  }
}

module appGwyApimManagementPublicDnsRecord 'modules/publicdns.bicep' = {
  scope: resourceGroup('external-dns-zones-rg')
  name: 'deployAppGwyApimManagementPublicDnsRecord'
  params: {
    zoneName: domainName
    ipAddress: applicationGatewayModule.outputs.appGwyPublicIpAddress
    recordName: 'management'
  }
}

output appGwyName string = applicationGatewayModule.outputs.appGwyName
output appGwyId string = applicationGatewayModule.outputs.appGwyId
output appGwyFqdn string = applicationGatewayModule.outputs.appGwyPublicDnsName
output appGwyPublicIpAddress string = applicationGatewayModule.outputs.appGwyPublicIpAddress
output apimPrivateIpAddress string = apiManagementModule.outputs.apimPrivateIpAddress
output funcAppName string = funcAppModule.outputs.funcAppName
output funcAppUri string = funcAppModule.outputs.funcAppUrl
output apimName string = apiManagementModule.outputs.apimName
output apimManagedIdentity string = apiManagementModule.outputs.apimManagedIdentityPrincipalId
