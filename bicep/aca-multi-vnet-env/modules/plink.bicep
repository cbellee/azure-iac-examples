param name string
param location string
param subnetId string
param groupId string
param acrName string

resource acr 'Microsoft.ContainerRegistry/registries@2023-08-01-preview' existing = {
  name: acrName
}

resource containerRegistryPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = {
  name: name
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: name
        properties: {
          groupIds: [
            groupId
          ]
          privateLinkServiceId: acr.id
        }
      }
    ]
    subnet: {
      id: subnetId
    }
  }
}
