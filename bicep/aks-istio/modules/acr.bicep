param location string

var affix = uniqueString(resourceGroup().id)
var name = 'acr${affix}'

resource acr 'Microsoft.ContainerRegistry/registries@2023-06-01-preview' = {
  name: name
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: false
    anonymousPullEnabled: false
  }
}

output acrName string = acr.name
