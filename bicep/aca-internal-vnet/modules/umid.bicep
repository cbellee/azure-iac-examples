param location string
param prefix string

var suffix = uniqueString(resourceGroup().id)
var name = '${prefix}-${suffix}-umid'

resource umid 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: name
  location: location
}

output name string = umid.name
output id string = umid.id
output principalId string = umid.properties.principalId
output clientId string = umid.properties.clientId
