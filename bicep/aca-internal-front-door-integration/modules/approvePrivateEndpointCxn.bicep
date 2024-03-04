param privateEndpointCxnName string
param privateLinkServiceName string

resource pls 'Microsoft.Network/privateLinkServices@2023-06-01' existing = {
  name: privateLinkServiceName
}

resource privateEndpointConnection 'Microsoft.Network/privateLinkServices/privateEndpointConnections@2023-06-01' = {
  name: privateEndpointCxnName
  parent: pls
  properties: {
    privateLinkServiceConnectionState: {
      status: 'Approved'
      description: 'Approved by Bicep'
    }
  }
}
