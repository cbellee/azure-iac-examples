param tags object = {
  costcentre: '1234567890'
  environment: 'dev'
}
param acrName string = '${uniqueString(resourceGroup().id)}acr'

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

output acrName string = acrName
output acrServer string = acr.properties.loginServer
output acrPassword string = listCredentials(acr.id, '2020-11-01-preview').passwords[0].value
output acrResourceId string = acr.id
