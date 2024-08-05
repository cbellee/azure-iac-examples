param location string
param tags object
param prefix string 
var acrName = '${prefix}acr${uniqueString(resourceGroup().id)}'

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: true
  }
}

output registryName string = acrName
output registryServer string = acr.properties.loginServer
output registryResourceId string = acr.id
