param vnetName string
param agcSubnetName string
param location string
param networkContributorRoleDefinitionId string = '4d97b98b-1d4f-4787-a291-c67834d212e7'

var umidName = 'azure-alb-identity'

resource umid 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: umidName
  location: location
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-08-01' existing = {
  name: vnetName
}

resource agcSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-08-01' existing = {
  parent: virtualNetwork
  name: agcSubnetName
}

resource networkContributorUmidAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(agcSubnet.name, umid.name)
  scope: agcSubnet
  properties: {
    principalId: umid.properties.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', networkContributorRoleDefinitionId)
    principalType: 'ServicePrincipal'
  }
}

output umidId string = umid.id
output umidName string = umid.name
output agcUmidPrincipalId string = umid.properties.principalId
