param location string
param adminGroupObjectId string
param sshPublicKey string
param kubernetesVersion string = '1.28.3'
param istioVersion string = 'asm-1-20'

module vnetModule 'modules/vnet.bicep' = {
  name: 'vnet-module'
  params: {
    location: location
    vnetAddressSpace: '10.1.0.0/16'
  }
}

module aksModule 'modules/aks.bicep' = {
  name: 'aks-module'
  params: {
    location: location
    adminGropuObjectId: adminGroupObjectId
    nodeSubnetId: vnetModule.outputs.nodeSubnetId
    sshPublicKey: sshPublicKey
    kubernetesVersion: kubernetesVersion
    linuxUsername: 'aksuser'
    vmSize: 'Standard_D2s_v3'
    istioVersion: istioVersion
  }
}

module rbac 'modules/roles.bicep' = {
  name: 'rbac-module'
  params: {
    location: location
    agcSubnetName: vnetModule.outputs.agcSubnetName
    vnetName: vnetModule.outputs.vnetName
  }
}

module agcModule 'modules/agc.bicep' = {
  name: 'agc-module'
  params: {
    location: location
    subnetId: vnetModule.outputs.agcSubnetId
  }
}

output umidId string = rbac.outputs.umidId
output umidName string = rbac.outputs.umidName
output agcSubnetId string = vnetModule.outputs.agcSubnetId
output agcId string = agcModule.outputs.id
output agcFrontend string = agcModule.outputs.frontendName
output agcUmidPrincipalId string = rbac.outputs.agcUmidPrincipalId
output agcName string = agcModule.outputs.name
output nodeResourceGroup string = aksModule.outputs.nodeResourceGroup
output clusterName string = aksModule.outputs.name
output rgId string = resourceGroup().id
