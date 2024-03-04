@allowed([
  'australiaeast'
  'australiasoutheast'
])
param location string
param adminGroupObjectId string
param tags object
param prefix string
param aksVersion string = '1.28.3'
param vmSku string = 'Standard_D4ds_v5'
param addressPrefix string
param subnets array
param sshPublicKey string

var readerRoleId = resourceId('Microsoft.Authorization/roleDefinitions', 'acdd72a7-3385-48ef-bd42-f606fba81ae7')
var contributorRoleId = resourceId('Microsoft.Authorization/roleDefinitions', 'b24988ac-6180-42a0-ab88-20f7382dd24c')

module wks './modules/wks.bicep' = {
  name: 'wksDeploy'
  params: {
    prefix: prefix
    tags: tags
    location: location
    retentionInDays: 30
  }
}

module vnet './modules/vnet.bicep' = {
  name: 'vnetDeploy'
  params: {
    prefix: prefix
    tags: tags
    addressPrefix: addressPrefix
    location: location
    subnets: subnets
  }
}

module acr './modules/acr.bicep' = {
  name: 'acrDeploy'
  params: {
    prefix: prefix
    tags: tags
    location: location
  }
}

module applicationGateway './modules/appGwy.bicep' = {
  name: 'applicationGatewayDeploy'
  dependsOn: [
    vnet
    wks
  ]
  params: {
    applicationGatewaySKU: 'WAF_v2'
    applicationGatewaySubnetId: vnet.outputs.subnets[2].id
    logAnalyticsWorkspaceId: wks.outputs.workspaceId
    prefix: prefix
    tags: tags
  }
}

module aks './modules/aks.bicep' = {
  name: 'aksDeploy'
  dependsOn: [
    vnet
    wks
    applicationGateway
  ]
  params: {
    prefix: prefix
    logAnalyticsWorkspaceId: wks.outputs.workspaceId
    aksDnsPrefix: prefix
    aksAgentOsDiskSizeGB: 60
    aksDnsServiceIP: '10.100.0.10'
    aksDockerBridgeCIDR: '172.17.0.1/16'
    aksEnableRBAC: true
    aksMaxNodeCount: 10
    aksMinNodeCount: 1
    aksNodeCount: 2
    aksNodeVMSize: vmSku
    aksServiceCIDR: '10.100.0.0/16'
    aksSystemSubnetId: vnet.outputs.subnets[0].id
    aksUserSubnetId: vnet.outputs.subnets[1].id
    aksVersion: aksVersion
    enableAutoScaling: true
    maxPods: 110
    networkPlugin: 'azure'
    enablePodSecurityPolicy: false
    tags: tags
    enablePrivateCluster: false
    linuxAdminUserName: 'localadmin'
    sshPublicKey: sshPublicKey
    adminGroupObjectID: adminGroupObjectId
    addOns: {
      azurepolicy: {
        enabled: true
        config: {
          version: 'v2'
        }
      }
      ingressApplicationGateway: {
        enabled: true
        config: {
          applicationGatewayId: applicationGateway.outputs.applicationGatewayId
          applicationGatewayWatchNamespace: 'project1,project2,default'
        }
      }
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: wks.outputs.workspaceId
        }
      }
    }
  }
}

resource appGwy 'Microsoft.Network/applicationGateways@2020-06-01' existing = {
  name: '${prefix}-appgwy'
}

resource applicationGatewayIngressReaderRoleAssigment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, applicationGateway.name, applicationGateway.name, readerRoleId)
  scope: resourceGroup()
  properties: {
    roleDefinitionId: readerRoleId
    principalId: aks.outputs.ingressApplicationGatewayObjectId
    principalType: 'ServicePrincipal'
  }
}

resource applicationGatewayIngressContributorRoleAssigment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(resourceGroup().id, applicationGateway.name, applicationGateway.name, contributorRoleId)
  scope: appGwy
  properties: {
    roleDefinitionId: contributorRoleId
    principalId: aks.outputs.ingressApplicationGatewayObjectId
    principalType: 'ServicePrincipal'
  }
}
