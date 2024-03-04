param location string
param name string

@allowed([
  'Basic'
  'Standard'
  'Premium'
])
param sku string

var affix = substring(uniqueString(resourceGroup().id), 0, 6)
var acrName = '${name}${affix}'

resource acr 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: acrName
  location: location
  sku: {
    name: sku
  }
  properties: {
    adminUserEnabled: true
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled'
      }
      retentionPolicy: {
        days: 7
        status: 'disabled'
      }
      exportPolicy: {
        status: 'enabled'
      }
    }
    encryption: {
      status: 'disabled'
    }
    dataEndpointEnabled: false
    publicNetworkAccess: 'Enabled'
    networkRuleBypassOptions: 'AzureServices'
    zoneRedundancy: 'Disabled'
  }
}

output name string = acr.name
output loginServer string = acr.properties.loginServer
output id string = acr.id
output password string = listCredentials(acr.id, '2021-12-01-preview').passwords[0].value
