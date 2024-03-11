param location string

var suffix = uniqueString(resourceGroup().id)
var name = 'acr${suffix}'

resource acr 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {
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

output name string = acr.name
