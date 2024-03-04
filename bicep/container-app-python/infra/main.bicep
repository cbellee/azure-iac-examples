param name string
param region1 string = 'canadacentral'
param region2 string = 'uksouth'
param containerPort int
param containerImage string
param acrName string
param acrPassword string
param acrLoginServer string
param dbAdminUserName string
param dbAdminPassword string
param dbSizeGB int = 32
param adminUserObjectId string
param tags object = {
  environment: 'dev'
  costCentre: '1234567890'
}

var suffix = substring(uniqueString(resourceGroup().id), 0, 6)
var secrets = [
  {
    name: 'registry-password'
    value: acrPassword
  }
]

module wksModule 'modules/wks.bicep' = {
  name: 'wks-deployment'
  params: {
    location: region1
    name: 'wks-${suffix}'
    tags: tags
  }
}

// Deploy vnets
module region1VnetModule 'modules/vnet.bicep' = {
  name: '${region1}-vnet-deployment'
  params: {
    location: region1
    name: 'vnet-${region1}-${suffix}'
    addressSpace: '10.1.0.0/16'
    subnets: [
      {
        name: 'DBSubnet'
        addressPrefix: '10.1.0.0/24'
        delegations: [
          {
            name: 'postgres-flex-server-delegation'
            properties: {
              serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
            }
          }
        ]
      }
      {
        name: 'ControlPlaneSubnet'
        addressPrefix: '10.1.8.0/21'
        delegations: null
      }
      {
        name: 'AppSubnet'
        addressPrefix: '10.1.16.0/21'
        delegations: null
      }
      {
        name: 'PrivateLinkSubnet'
        addressPrefix: '10.1.24.0/24'
        delegations: null
      }
    ]
  }
}

module region2VnetModule 'modules/vnet.bicep' = {
  name: '${region2}-vnet-deployment'
  params: {
    location: region2
    name: 'vnet-${region2}-${suffix}'
    addressSpace: '10.2.0.0/16'
    subnets: [
      {
        name: 'DBSubnet'
        addressPrefix: '10.2.0.0/24'
        delegations: [
          {
            name: 'postgres-flex-server-delegation'
            properties: {
              serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
            }
          }
        ]
      }
      {
        name: 'PrivateLinkSubnet'
        addressPrefix: '10.2.1.0/24'
        delegations: null
      }
    ]
  }
}

// Peer vnets
module region1ToRegion2Peer 'modules/peering.bicep' = {
  name: '${region1}-to-${region2}-peer'
  params: {
    localVnetName: region1VnetModule.outputs.vnet.name
    remoteVnetName: region2VnetModule.outputs.vnet.name
    remoteVnetId: region2VnetModule.outputs.vnet.id
  }
}

module region2ToRegion1Peer 'modules/peering.bicep' = {
  name: '${region2}-to-${region1}-peer'
  params: {
    localVnetName: region2VnetModule.outputs.vnet.name
    remoteVnetName: region1VnetModule.outputs.vnet.name
    remoteVnetId: region1VnetModule.outputs.vnet.id
  }
}

// private link
module module_acr_private_link './modules/private_link.bicep' = {
  name: 'module-acr-private-link'
  params: {
    suffix: suffix
    location: region1
    resourceType: 'Microsoft.ContainerRegistry/registries'
    resourceName: acrName
    groupId: 'registry'
    subnet: reference(resourceId('Microsoft.Resources/deployments', '${region1}-vnet-deployment')).outputs.vnet.value.subnets[3].id
  }
  dependsOn: [
    region1VnetModule
  ]
}

module module_acr_private_dns_group './modules/private_dns_zone_group.bicep' = {
  name: 'module-acr-private-dns-group'
  params: {
    privateEndpointName: module_acr_private_link.outputs.privateEndpointName
    zoneConfigs: [
      {
        name: acrPrivateDnsZone.name
        properties: {
          privateDnsZoneId: acrPrivateDnsZone.id
        }
      }
    ]
  }
}

// acr private dns zone
resource acrPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurecr.io'
  location: 'global'
}

// create private DNS zones
module region1PostGreSQLPrivateDnsZone 'modules/private_dns_zone.bicep' = {
  name: '${region1}.postgres.database.azure.com'
  params: {
    privateDnsZoneName: '${region1}.postgres.database.azure.com'
  }
}

module region2PostGreSQLPrivateDnsZone 'modules/private_dns_zone.bicep' = {
  name: '${region2}.postgres.database.azure.com'
  params: {
    privateDnsZoneName: '${region2}.postgres.database.azure.com'
  }
}

// link DNS zones to vnets
module region1ToRegion1PostGreSQLPrivateDnsZoneLink 'modules/private_dns_zone_link.bicep' = {
  name: 'module-${region1}-to-${region1}-vnet-link'
  params: {
    privateDnsZoneName: region1PostGreSQLPrivateDnsZone.name
    vnetRef: region1VnetModule.outputs.vnet.id
    vnetName: region1VnetModule.outputs.vnet.name
  }
}

module region2ToRegion2PostGreSQLPrivateDnsZoneLink 'modules/private_dns_zone_link.bicep' = {
  name: 'module-${region2}-to-${region2}-vnet-link'
  params: {
    privateDnsZoneName: region2PostGreSQLPrivateDnsZone.name
    vnetRef: region2VnetModule.outputs.vnet.id
    vnetName: region2VnetModule.outputs.vnet.name
  }
}

module region1ToRegion2PostGreSQLPrivateDnsZoneLink 'modules/private_dns_zone_link.bicep' = {
  name: 'module-${region1}-to-${region2}-vnet-link'
  params: {
    privateDnsZoneName: region1PostGreSQLPrivateDnsZone.name
    vnetRef: region2VnetModule.outputs.vnet.id
    vnetName: region2VnetModule.outputs.vnet.name
  }
}

module region2ToRegion1PostGreSQLPrivateDnsZoneLink 'modules/private_dns_zone_link.bicep' = {
  name: 'module-${region2}-to-${region1}-vnet-link'
  params: {
    privateDnsZoneName: region2PostGreSQLPrivateDnsZone.name
    vnetRef: region1VnetModule.outputs.vnet.id
    vnetName: region1VnetModule.outputs.vnet.name
  }
}

// link DNS zones to vnets
resource acrPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${region1}-to-acr-vnet-link'
  location: 'global'
  parent: acrPrivateDnsZone
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: region1VnetModule.outputs.vnet.id
    }
  }
}

// Deploy region 1 PostGeSQL server & database
module region1PostGreSQLModule './modules/postgesql-flex.bicep' = {
  dependsOn: [
    region1ToRegion1PostGreSQLPrivateDnsZoneLink
    region2ToRegion2PostGreSQLPrivateDnsZoneLink
    region1ToRegion2PostGreSQLPrivateDnsZoneLink
    region2ToRegion1PostGreSQLPrivateDnsZoneLink
  ]
  name: '${region1}-postgresql'
  params: {
    adminLoginName: dbAdminUserName
    adminPassword: dbAdminPassword
    postGreSQLDbName: 'testdb'
    storageSizeGB: dbSizeGB
    dnsZoneId: region1PostGreSQLPrivateDnsZone.outputs.dnsZoneId
    location: region1
    name: region1
    subnetId: region1VnetModule.outputs.vnet.subnets[0].id
  }
}

// Deploy region 2 PostGeSQL server & database
module region2PostGreSQLModule './modules/postgesql-flex.bicep' = {
  dependsOn: [
    region1ToRegion1PostGreSQLPrivateDnsZoneLink
    region2ToRegion2PostGreSQLPrivateDnsZoneLink
    region1ToRegion2PostGreSQLPrivateDnsZoneLink
    region2ToRegion1PostGreSQLPrivateDnsZoneLink
  ]
  name: '${region2}-postgresql'
  params: {
    adminLoginName: dbAdminUserName
    adminPassword: dbAdminPassword
    postGreSQLDbName: 'testdb'
    storageSizeGB: dbSizeGB
    dnsZoneId: region2PostGreSQLPrivateDnsZone.outputs.dnsZoneId
    location: region2
    name: region2
    subnetId: region2VnetModule.outputs.vnet.subnets[0].id
  }
}

// Deploy Key vault to store DB connection strings 
resource keyVault 'Microsoft.KeyVault/vaults@2021-11-01-preview' = {
  location: region1
  name: '${name}-kv-${suffix}'
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: false
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        objectId: adminUserObjectId
        permissions: {
          certificates: [
            'all'
          ]
          keys: [
            'all'
          ]
          secrets: [
            'all'
          ]
          storage: [
            'all'
          ]
        }
        tenantId: subscription().tenantId
      }
    ]
  }
}

// Deploy secerts to key vault
resource dbSecret1 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  name: '${keyVault.name}/${region1}-db-cxn'
  properties: {
    attributes: {
      enabled: true
    }
    value: region1PostGreSQLModule.outputs.postGreSQLCxn
  }
}

resource dbSecret2 'Microsoft.KeyVault/vaults/secrets@2021-11-01-preview' = {
  name: '${keyVault.name}/${region2}-db-cxn'
  properties: {
    attributes: {
      enabled: true
    }
    value: region2PostGreSQLModule.outputs.postGreSQLCxn
  }
}

// create Container app service
resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2022-01-01-preview' = {
  location: region1
  name: 'my-container-environment'
  properties: {
    vnetConfiguration: {
      infrastructureSubnetId: region1VnetModule.outputs.vnet.subnets[1].id
      runtimeSubnetId: region1VnetModule.outputs.vnet.subnets[2].id
      internal: false
    }
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: wksModule.outputs.workspaceCustomerId
        sharedKey: wksModule.outputs.workspaceSharedKey
      }
    }
  }
  tags: tags
}

resource frontEndApp 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: 'python-app'
  location: region1
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    configuration: {
      activeRevisionsMode: 'single'
      secrets: secrets
      registries: [
        {
          passwordSecretRef: 'registry-password'
          server: acrLoginServer
          username: acrName
        }
      ]
      ingress: {
        external: true
        targetPort: containerPort
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
        transport: 'http'
      }
    }
    managedEnvironmentId: containerAppEnvironment.id
    template: {
      containers: [
        {
          image: containerImage
          name: 'python-app'
          resources: {
            cpu: '0.25'
            memory: '0.5Gi'
          }
          env: [
            {
              name: 'DB_CONNECTION_STRING'
              value: region2PostGreSQLModule.outputs.postGreSQLCxn
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 10
      }
    }
  }
}
 output latestRevisionFqdn string = frontEndApp.properties.latestRevisionFqdn
