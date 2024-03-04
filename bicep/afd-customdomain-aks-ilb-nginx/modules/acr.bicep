param location string
param tags object

@allowed([
  true
  false
])
param isAdminUserEnabled bool = false

@allowed([
  true
  false
])
param isAnonymousPullEnabled bool = false

@allowed([
  'Disabled'
  'Enabled'
])
param isPublicNetworkAccessEnabled string = 'Enabled'
param prefix string

var affix = uniqueString(resourceGroup().id)
var p = replace(prefix, '-', '')
var acrName = toLower(format('{0}{1}', p, affix))

resource acr 'Microsoft.ContainerRegistry/registries@2020-11-01-preview' = {
  name: acrName
  location: location
  tags: tags
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: isAdminUserEnabled
    anonymousPullEnabled: isAnonymousPullEnabled
    publicNetworkAccess: isPublicNetworkAccessEnabled
  }
}

output registryName string = acr.name
output registryServer string = acr.properties.loginServer
output registryResourceId string = acr.id
