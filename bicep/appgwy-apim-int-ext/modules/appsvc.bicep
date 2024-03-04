@allowed([
  'P1v2'
  'P2v2'
  'P3v2'
])
param skuName string = 'P1v2'
param containerName string
param vnetIntegrationSubnetId string

var suffix = uniqueString(resourceGroup().id)
var siteName = 'app-${suffix}'
var serverFarmName = 'app-svc-${suffix}'

resource serverFarm 'Microsoft.Web/serverfarms@2020-12-01' = {
  kind: 'linux'
  location: resourceGroup().location
  name: serverFarmName
  sku: {
    name: skuName
    tier: 'PremiumV2'
    size: skuName
    family: skuName
    capacity: 1
  }
  properties: {
    reserved: true
  }
}


resource webApp 'Microsoft.Web/sites@2020-06-01' = {
  name: siteName
  location: resourceGroup().location
  kind: 'app,linux,container'
  properties: {
    serverFarmId: serverFarm.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerName}'
    }
  }
}

resource webAppAppSettings 'Microsoft.Web/sites/config@2020-06-01' = {
  name: '${webApp.name}/appsettings'
  properties: {
    'WEBSITE_DNS_SERVER': '168.63.129.16'
    'WEBSITE_VNET_ROUTE_ALL': '1'
    'WEBSITES_ENABLE_APP_SERVICE_STORAGE': false
    'DOCKER_REGISTRY_SERVER_URL': 'https://index.docker.io/v1'
  }
}

resource webAppNetworkConfig 'Microsoft.Web/sites/networkConfig@2020-06-01' = {
  name: '${webApp.name}/VirtualNetwork'
  properties: {
    subnetResourceId: vnetIntegrationSubnetId
  }
}

/* resource appSvcPrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  location: resourceGroup().location
  tags: tags
  name: 'appSvcPrivateEndpoint'
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'appSvcConnection'
        properties: {
          privateLinkServiceId: webApp.id
          groupIds: [
            'sites'
          ]
        }
      }
    ]
  }
}

resource appSvcPrivateEndpointDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location: 'global'
  tags: tags
  name: appSvcPrivateDNSZoneName
  properties: {}
}

resource AppSvcHubVirtualNetworkDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${appSvcPrivateEndpointDnsZone.name}/${appSvcPrivateEndpointDnsZone.name}-hub-link'
  tags: tags
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hubVnetId
    }
  }
}

resource AppSvcApokeVirtualNetworkDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${appSvcPrivateEndpointDnsZone.name}/${appSvcPrivateEndpointDnsZone.name}-spoke-link'
  tags: tags
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: spokeVnetId
    }
  }
}

resource appSvcPrivateDNSZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${appSvcPrivateEndpoint.name}/dnsGroup1'
  dependsOn: [
    appSvcPrivateEndpointDnsZone
  ]
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: appSvcPrivateEndpointDnsZone.id
        }
      }
    ]
  }
} */

output webAppName string = webApp.name
output webAppUrl string = webApp.properties.defaultHostName
