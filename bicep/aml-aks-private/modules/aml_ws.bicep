param location string
param applicationInsightsId string
param containerRegistryId string
param keyVaultId string
param storageId string
param amlComputeName string
param amlAksComputeName string
param workspaceName string
param aksClusterId string
param loadBalancerSubnetName string
param amlComputeSubnetId string
param agentCount int

@description('The VM size for compute instance')
param vmSize string = 'Standard_DS3_v2'

@description('AAD tenant id of the user to which compute instance is assigned to')
param tenantId string = subscription().tenantId

@description('AAD object id of the user to which compute instance is assigned to')
param objectId string

@description('inline command')
param inlineCommand string = 'ls'

@description('Specifies the cmd arguments of the creation script in the storage volume of the Compute Instance.')
param creationScript_cmdArguments string = ''

resource aml_ws 'Microsoft.MachineLearningServices/workspaces@2023-06-01-preview' = {
  name: workspaceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    applicationInsights: applicationInsightsId
    containerRegistry: containerRegistryId
    imageBuildCompute: amlComputeName
    friendlyName: 'secure-aml-workspace'
    keyVault: keyVaultId
    primaryUserAssignedIdentity: ''
    publicNetworkAccess: 'Disabled'
    storageAccount: storageId
    description: 'secure aml workspace'
    allowPublicAccessWhenBehindVnet: false
    hbiWorkspace: true
    /* encryption: {
      keyVaultProperties: {
        keyVaultArmId: module_kv.outputs.keyVaultId
        keyIdentifier: ''
      }
      status: 'Enabled'
      cosmosDbResourceId: ''
      searchAccountResourceId: ''
      storageAccountResourceId: module_stor.outputs.storageAccountId
    } */
  }
}

resource workspace_compute 'Microsoft.MachineLearningServices/workspaces/computes@2021-07-01' = {
  name: amlComputeName
  parent: aml_ws
  location: location
  properties: {
    computeType: 'ComputeInstance'
    properties: {
      vmSize: vmSize
      subnet: {
        id: amlComputeSubnetId
      }
      personalComputeInstanceSettings: {
        assignedUser: {
          objectId: objectId
          tenantId: tenantId
        }
      }
      setupScripts: {
        scripts: {
          creationScript: {
            scriptSource: 'inline'
            scriptData: base64(inlineCommand)
            scriptArguments: creationScript_cmdArguments
          }
        }
      }
    }
  }
}

resource amlAksCompute 'Microsoft.MachineLearningServices/workspaces/computes@2021-07-01' = {
  name: amlAksComputeName
  location: location
  parent: aml_ws
  properties: {
    description: 'aks inference cluster'
    resourceId: aksClusterId
    computeType: 'AKS'
    properties: {
      loadBalancerType: 'InternalLoadBalancer'
      loadBalancerSubnet: loadBalancerSubnetName
      agentCount: agentCount
    }
  }
}

output amlWorkspaceName string = aml_ws.name
output amlWorkspaceId string = aml_ws.id
