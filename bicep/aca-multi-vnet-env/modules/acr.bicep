param name string 
param location string
param isAnonymousPullEnabled bool = false
param isAdminUserEnabled bool = false
param isDataEndpointEnabled bool = true

@allowed([
  'Standard'
  'Premium'
])
param sku string = 'Premium'

resource acr 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' = {
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
