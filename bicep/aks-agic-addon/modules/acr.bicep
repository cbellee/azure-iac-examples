param tags object
param prefix string 
param location string

@allowed([
  'Basic'
  'Premium'
  'Standard'
])
param sku string = 'Standard'

var acrName = '${prefix}acr${uniqueString(resourceGroup().id)}'

resource acr 'Microsoft.ContainerRegistry/registries@2020-11-01-preview' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: true
  }
}

output registryName string = acrName
output registryServer string = acr.properties.loginServer
output registryResourceId string = acr.id
