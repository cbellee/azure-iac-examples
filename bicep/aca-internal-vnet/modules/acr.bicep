param location string
param isAnonymousPullEnabled bool = false
param isAdminUserEnabled bool = false
param isDataEndpointEnabled bool = true
param prefix string

@allowed([
  'Standard'
  'Premium'
])
param sku string = 'Premium'

var suffix = uniqueString(resourceGroup().id)
var name = '${prefix}acr${suffix}'

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
  name: name
  location: location
  sku: {
    name: sku
  }
  properties: {
    dataEndpointEnabled: isDataEndpointEnabled
    adminUserEnabled: isAdminUserEnabled
    anonymousPullEnabled: isAnonymousPullEnabled
  }
}

output name string = acr.name
output loginServer string = acr.properties.loginServer
