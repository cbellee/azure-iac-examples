param locations array = [
  'australiaeast'
  'australiasoutheast'
]
param adminGroupObjectID string
param tags object
param k8sVersion string
param vmSku string
param addressPrefixes array
param subnets array
param sshPublicKey string
param userName string = 'localadmin'
param dnsPrefix string
param prefix string = 'afd-aks'
param userPrincipalId string

targetScope = 'subscription'

resource resourceGroups 'Microsoft.Resources/resourceGroups@2021-04-01' = [for (location, index) in locations: {
  name: '${prefix}-${locations[index]}-rg'
  location: locations[index]
  tags: tags
}]

module wksDeployment 'modules/azureMonitor.bicep' = [for (location, index) in locations: {
  name: 'azmon-module-${location}'
  scope: resourceGroup(resourceGroups[index].name)
  params: {
    location: location
    prefix: prefix
    sku: 'PerGB2018'
  }
}]

module keyVaultDeployment 'modules/keyvault.bicep' = [for (location, index) in locations: {
  name: 'kv-module-${location}'
  scope: resourceGroup(resourceGroups[index].name)
  params: {
    location: location
    prefix: prefix
    isRbacEnabled: true
    principalId: userPrincipalId
  }
}]

module vnetDeployment './modules/vnet.bicep' = [for (location, index) in locations: {
  name: 'vnet-module-${location}'
  scope: resourceGroup(resourceGroups[index].name)
  params: {
    prefix: prefix
    tags: tags
    addressPrefix: addressPrefixes[index]
    location: location
    subnets: subnets
  }
}]

module azureContainerRegistry './modules/acr.bicep' = [for (location, index) in locations: {
  name: 'acr-module-${location}'
  scope: resourceGroup(resourceGroups[index].name)
  params: {
    location: location
    tags: tags
    prefix: prefix
    isAdminUserEnabled: false
    isAnonymousPullEnabled: false
    isPublicNetworkAccessEnabled: 'Enabled'
  }
}]

module aksDeployment './modules/aks.bicep' = [for (location, index) in locations: {
  name: 'aks-module-${location}'
  scope: resourceGroup(resourceGroups[index].name)
  dependsOn: [
    vnetDeployment
    wksDeployment
  ]
  params: {
    location: location
    prefix: prefix
    vnetName: vnetDeployment[index].outputs.vnetName
    logAnalyticsWorkspaceId: wksDeployment[index].outputs.workspaceId
    aksAgentOsDiskSizeGB: 60
    aksDnsServiceIP: '10.100.0.10'
    aksServiceCIDR: '10.100.0.0/16'
    aksDnsPrefix: dnsPrefix
    aksEnableRBAC: true
    aksMaxNodeCount: 10
    aksMinNodeCount: 1
    aksNodeCount: 2
    aksNodeVMSize: vmSku
    aksSystemSubnetId: vnetDeployment[index].outputs.subnets[0].id
    aksUserSubnetId: vnetDeployment[index].outputs.subnets[1].id
    k8sVersion: k8sVersion
    enableAutoScaling: true
    maxPods: 110
    networkPlugin: 'azure'
    enablePodSecurityPolicy: false
    tags: tags
    enablePrivateCluster: false
    linuxAdminUserName: userName
    sshPublicKey: sshPublicKey
    adminGroupObjectID: adminGroupObjectID
    addOns: {
      azureKeyvaultSecretsProvider: {
        enabled: true
        config: {
          enableSecretRotation: 'true'
          rotationPollInterval: '2m'
        }
      }
      azurepolicy: {
        enabled: true
        config: {
          version: 'v2'
        }
      }
      omsagent: {
        enabled: true
        config: {
          logAnalyticsWorkspaceResourceID: wksDeployment[index].outputs.workspaceId
        }
      }
    }
  }
}]

module vmDeployment 'modules/vm.bicep' = [for (location, index) in locations: {
  name: 'vm-module-${location}'
  scope: resourceGroup(resourceGroups[index].name)
  params: {
    location: location
    sshKey: sshPublicKey
    prefix: prefix
    subnetId: vnetDeployment[index].outputs.subnets[3].id
  }
}]

module bastionDeployment 'modules/bastion.bicep' = [for (location, index) in locations: {
  name: 'bastion-module-${location}'
  scope: resourceGroup(resourceGroups[index].name)
  params: {
    prefix: prefix
    location: location
    subnetId: vnetDeployment[index].outputs.subnets[5].id
  }
}]

output clusters array = [for (deployment, index) in locations: {
  name: aksDeployment[index].outputs.name
  fqdn: aksDeployment[index].outputs.id
  oidcIssuer: aksDeployment[index].outputs.oidcIssuerUrl
  nodeResourceGroup: aksDeployment[index].outputs.aksNodeResourceGroupName
  resourceGroup: aksDeployment[index].outputs.resourceGroupName
  keyVaultProviderClientId: aksDeployment[index].outputs.azureKeyvaultSecretsProviderClientId
  keyVaultProviderResourceId: aksDeployment[index].outputs.azureKeyvaultSecretsProviderResourceId
}]

output bastions array = [for (deployment, index) in locations: {
  name: bastionDeployment[index].outputs.name
  id: bastionDeployment[index].outputs.id
}]

output keyVaults array = [for (deployment, index) in locations: {
  name: keyVaultDeployment[index].outputs.name
  id: keyVaultDeployment[index].outputs.id
}]

output virtualMachines array = [for (deployment, index) in locations: {
  name: vmDeployment[index].outputs.name
  id: vmDeployment[index].outputs.id
}]
