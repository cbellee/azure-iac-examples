
param hubVnetName string = 'hub-vnet'
param hubVnetAddressPrefix string = '10.0.0.0/16'
param myExternalIp string
param tags object = {
  costcentre: '1234567890'
  environment: 'dev'
}
param hubSubnets array = [
  {
    name: 'PrivateLink-Subnet'
    addressPrefix: '10.0.0.0/24'
    delegations: []
  }
  {
    name: 'NetApp-Subnet'
    addressPrefix: '10.0.1.0/24'
    delegations: []
  }
]

var suffix = uniqueString(resourceGroup().id)
var acrName = 'acr${suffix}'
var acrPrivateDNSZoneName = 'privatelink.azurecr.io'

// vnet + subnets
module hubVnetModule './modules/vnet.bicep' = {
  name: hubVnetName
  params: {
    tags: tags
    vnetName: hubVnetName
    subnets: hubSubnets
    vnetAddressPrefix: hubVnetAddressPrefix
  }
}

// ACR + PLink + DNS Zone
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
          value: '${myExternalIp}/32'
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
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', hubVnetModule.outputs.vnetName, hubVnetModule.outputs.subnetArray[0].name)
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
      id: hubVnetModule.outputs.id
    }
  }
}

output vnetName string = hubVnetModule.outputs.vnetName
output vnetId string = hubVnetModule.outputs.id
output dnsZoneId string = acrPrivateEndpointDnsZone.id
output acrLoginServer string = acr.properties.loginServer
output acrPassword string = (listCredentials(acr.id, acr.apiVersion)).passwords[0].value
output acrName string = acr.name
