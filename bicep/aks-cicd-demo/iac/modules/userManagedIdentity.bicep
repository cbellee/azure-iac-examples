param location string
param name string
param tags object

resource userManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2022-01-31-preview' = {
  name: name
  location: location
  tags: tags
}

output principalId string = userManagedIdentity.properties.principalId
output id string = userManagedIdentity.id
