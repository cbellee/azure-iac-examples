param location string
param tags object
param name string

resource acr 'Microsoft.ContainerRegistry/registries@2020-11-01-preview' = {
  name: name
  location: location
  tags: tags
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: true
  }
}

output registryName string = name
output registryServer string = acr.properties.loginServer
output registryResourceId string = acr.id
