param location string
param name string

resource user_assigned_identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  location: location
  name: name
}

output name string = user_assigned_identity.name
output clientId string = user_assigned_identity.properties.clientId
output principalId string = user_assigned_identity.properties.principalId
output tenantId string = user_assigned_identity.properties.tenantId
output id string = user_assigned_identity.id
