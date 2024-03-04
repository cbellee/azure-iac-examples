param tags object
var acrName = 'acr${uniqueString(resourceGroup().id)}'

resource acr 'Microsoft.ContainerRegistry/registries@2020-11-01-preview' = {
  name: acrName
  location: resourceGroup().location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
  }
}

output registryName string = acrName
output registryServer string = acr.properties.loginServer
output registryPassword string = listCredentials(acr.id, '2020-11-01-preview').passwords[0].value
output registryResourceId string = acr.id
