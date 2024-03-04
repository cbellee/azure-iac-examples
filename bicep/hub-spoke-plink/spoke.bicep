// App Service (containers) + Regional Vnet Integration + limit access by X-AZFD-ID header

param mySqlAdminUserName string = 'dbadmin'
param mySqlAdminPassword string
param hubVnetPeeringDeploymentName string = 'hubVnetPeeringDeployment-${utcNow()}'
param spokeVnetName string = 'spoke-vnet'
param spokeVnetAddressPrefix string = '10.1.0.0/16'
param dockerRegistryUrl string
param acrUserName string
param acrPassword string 

param tags object = {
  costcenter: '1234567890'
  environment: 'dev'
}
param spokeSubnets array = [
  {
    name: 'PrivateLink-Subnet'
    addressPrefix: '10.1.0.0/24'
    delegations: []
  }
  {
    name: 'Database-Subnet'
    addressPrefix: '10.1.1.0/24'
    delegations: [
      {
        name: 'delegation'
        properties: {
          serviceName: 'Microsoft.DBforMySQL/flexibleServers'
        }
      }
    ]
  }
  {
    name: 'AppService-Subnet'
    addressPrefix: '10.1.2.0/24'
    delegations: [
      {
        name: 'delegation'
        properties: {
          serviceName: 'Microsoft.Web/serverfarms'
        }
      }
    ]
  }
]
@allowed([
  'P1v2'
  'P2v2'
  'P3v2'
])
param skuName string = 'P1v2'
param containerName string
param hubVnetId string
param hubVnetName string
param hubVnetResourceGroup string

var suffix = uniqueString(resourceGroup().id)
var siteName = 'my-app-${suffix}'
var storageName = 'stor${suffix}'
var storagePrivateDNSZoneName = 'privatelink.blob.core.windows.net'
var appSvcPrivateDNSZoneName = 'azurewebsites.windows.net'
var mySqlPrivateDNSZoneName = 'mysql.database.azure.com'
var serverFarmName = 'app-svc-${suffix}'

// vnet + subnets
module spokeVnetModule './modules/vnet.bicep' = {
  name: spokeVnetName
  params: {
    tags: tags
    vnetName: spokeVnetName
    subnets: spokeSubnets
    vnetAddressPrefix: spokeVnetAddressPrefix
  }
}

resource vnetPeeringToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-08-01' = {
  name: '${spokeVnetName}/peering-to-${hubVnetName}'
  dependsOn: [
    spokeVnetModule
  ]
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    allowVirtualNetworkAccess: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: hubVnetId
    }
  }
}

module vnetPeeringFromHubModule './modules/peering.bicep' = {
  name: hubVnetPeeringDeploymentName
  scope: resourceGroup(hubVnetResourceGroup)
  dependsOn: [
    spokeVnetModule
  ]
  params: {
    remoteVnetName: spokeVnetModule.outputs.vnetName
    remoteVnetId: spokeVnetModule.outputs.id
    parentVnetName: hubVnetName
    useRemoteGateways: false
  }
}

// Storage + Private endpoint + DNS Zone
resource storage 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: storageName
  tags: tags
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: true
    networkAcls: {
      defaultAction: 'Deny'
    }
    supportsHttpsTrafficOnly: true
  }
}

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
    'DOCKER_REGISTRY_SERVER_URL': dockerRegistryUrl //'https://index.docker.io/v1'
    'DOCKER_REGISTRY_SERVER_USERNAME': acrUserName
    'DOCKER_REGISTRY_SERVER_PASSWORD': acrPassword
    'WEBSITE_PULL_IMAGE_OVER_VNET': true
  }
}

resource webAppNetworkConfig 'Microsoft.Web/sites/networkConfig@2020-06-01' = {
  name: '${webApp.name}/VirtualNetwork'
  properties: {
    subnetResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', spokeVnetModule.outputs.vnetName, spokeVnetModule.outputs.subnetArray[2].name)
  }
}

resource blobPrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  location: resourceGroup().location
  tags: tags
  name: 'blobPrivateEndpoint'
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', spokeVnetModule.outputs.vnetName, spokeVnetModule.outputs.subnetArray[0].name)
    }
    privateLinkServiceConnections: [
      {
        name: 'blobStorageConnection'
        properties: {
          groupIds: [
            'blob'
          ]
          privateLinkServiceId: storage.id
        }
      }
    ]
  }
}

resource appSvcPrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  location: resourceGroup().location
  tags: tags
  name: 'appSvcPrivateEndpoint'
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', spokeVnetModule.outputs.vnetName, spokeVnetModule.outputs.subnetArray[0].name)
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

resource blobPrivateEndpointDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location: 'global'
  tags: tags
  name: storagePrivateDNSZoneName
  properties: {}
}

resource virtualNetworkStorageDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${blobPrivateEndpointDnsZone.name}/${blobPrivateEndpointDnsZone.name}-link'
  tags: tags
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: spokeVnetModule.outputs.id
    }
  }
}

resource appSvcPrivateEndpointDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location: 'global'
  tags: tags
  name: appSvcPrivateDNSZoneName
  properties: {}
}

resource virtualNetworkAppSvcDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${appSvcPrivateEndpointDnsZone.name}/${appSvcPrivateEndpointDnsZone.name}-link'
  tags: tags
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: spokeVnetModule.outputs.id
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
}

resource blobStoragePrivateDNSZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-11-01' = {
  name: '${blobPrivateEndpoint.name}/dnsGroup2'
  dependsOn: [
    blobPrivateEndpointDnsZone
  ]
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: blobPrivateEndpointDnsZone.id
        }
      }
    ]
  }
}

module mySqlFlexServerModule 'modules/mysqlFlexServer.bicep' = {
  name: 'mySqlFlexServerDeployment'
  params: {
    location: resourceGroup().location
    mySqlAdminUserName: mySqlAdminUserName
    mySqlAdminPassword: mySqlAdminPassword
    subnetArmResourceId: resourceId('Microsoft.Network/virtualNetworks/subnets', spokeVnetModule.outputs.vnetName, spokeVnetModule.outputs.subnetArray[1].name)
    suffix: suffix
  }
}

resource mySqlPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location: 'global'
  tags: tags
  name: mySqlPrivateDNSZoneName
  properties: {
  }
}

/* resource mySqlPrivateDnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: mySqlServerName
  parent: mySqlPrivateDnsZone
  properties: {
    aRecords: [
      {
        ipv4Address: mySqlFlexServerModule.outputs.
      }
    ]
  }
} */

resource virtualNetworkMySqlDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${mySqlPrivateDnsZone.name}/${mySqlPrivateDnsZone.name}-link'
  tags: tags
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: spokeVnetModule.outputs.id
    }
  }
}

output vnetName string = spokeVnetModule.outputs.vnetName
output vnetId string = spokeVnetModule.outputs.id
output storageDnsZoneId string = blobPrivateEndpointDnsZone.id
output webAppName string = webApp.name
output webAppHostName string = webApp.properties.defaultHostName
output webAppPrivateEndpointIpAddress string = appSvcPrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
