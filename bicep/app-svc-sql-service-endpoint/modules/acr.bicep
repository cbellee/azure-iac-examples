param location string
param tags object

var suffix = uniqueString(resourceGroup().id)
var acrName = 'acr${suffix}'

resource acr 'Microsoft.ContainerRegistry/registries@2020-11-01-preview' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
  }
}

output acrLoginServer string = acr.properties.loginServer
output acrName string = acr.name
