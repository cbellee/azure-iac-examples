param location string = resourceGroup().location
param anonymousPullEnabled bool = false

var affix = uniqueString(resourceGroup().id)
var acrName = '${affix}acr'

resource acr 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' = {
  name: acrName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
    anonymousPullEnabled: anonymousPullEnabled
  }
}

output acrName string = acr.name
