param privateLinkServiceName string

resource pls 'Microsoft.Network/privateLinkServices@2023-06-01' existing = {
  name: privateLinkServiceName
}

output peCxnName string = pls.properties.privateEndpointConnections[0].name
