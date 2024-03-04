param location string
param name string

resource user_assigned_identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  location: location
  name: name
}

output uamiName string = user_assigned_identity.name
output uamiClientId string = user_assigned_identity.properties.clientId
output uamiPrincipalId string = user_assigned_identity.properties.principalId
output uamiTenantId string = user_assigned_identity.properties.tenantId
