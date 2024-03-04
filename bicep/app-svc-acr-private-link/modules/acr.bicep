param externalIp string
param vnetId string
param subnetId string

var suffix = uniqueString(resourceGroup().id)
var acrName = 'acr${suffix}'
var acrPrivateDNSZoneName = 'privatelink.azurecr.io'

resource acr 'Microsoft.ContainerRegistry/registries@2020-11-01-preview' = {
  name: acrName
  location: resourceGroup().location
  sku: {
    name: 'Premium'
  }
  properties: {
    adminUserEnabled: true
    networkRuleSet: {
      defaultAction: 'Deny'
      ipRules: [
        {
          action: 'Allow'
          value: '${externalIp}/32'
        }
      ]
    }
  }
}

resource acrPrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  location: resourceGroup().location
  name: 'acrPrivateEndpoint'
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'acrConnection'
        properties: {
          groupIds: [
            'registry'
          ]
          privateLinkServiceId: acr.id
        }
      }
    ]
  }
}

resource acrPrivateEndpointDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location: 'global'
  name: acrPrivateDNSZoneName
  properties: {}
}

resource acrPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${acrPrivateEndpointDnsZone.name}/${acrPrivateEndpointDnsZone.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnetId
    }
  }
}

output acrLoginServer string = acr.properties.loginServer
output acrName string = acr.name
output acrPassword string = (listCredentials(acr.id, acr.apiVersion)).passwords[0].value
