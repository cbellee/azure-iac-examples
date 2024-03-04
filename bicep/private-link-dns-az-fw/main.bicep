param prefix string
param localGatewayIpAddress string
param vpnSharedSecret string
param sshKey string = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDCKEnblRrHUsUf2zEhDC4YrXVDTf6Vj3eZhfIT22og0zo2hdpfUizcDZ+i0J4Bieh9zkcsGMZtMkBseMVVa5tLSNi7sAg79a8Bap5RmxMDgx53ZCrJtTC3Li4e/3xwoCjnl5ulvHs6u863G84o8zgFqLgedKHBmJxsdPw5ykLSmQ4K6Qk7VVll6YdSab7R6NIwW5dX7aP2paD8KRUqcZ1xlArNhHiUT3bWaFNRRUOsFLCxk2xyoXeu+kC9HM2lAztIbUkBQ+xFYIPts8yPJggb4WF6Iz0uENJ25lUGen4svy39ZkqcK0ZfgsKZpaJf/+0wUbjqW2tlAMczbTRsKr8r cbellee@CB-SBOOK-1809'
param availabilityZones array = [
  '1'
  '2'
  '3'
]
param hubVnetAddressPrefix string = '10.0.0.0/16'
param hubSubnets array = [
  {
    name: 'GatewaySubnet'
    addressPrefix: '10.0.0.0/24'
  }
  {
    name: 'AzureFirewallSubnet'
    addressPrefix: '10.0.1.0/24'
  }
  {
    name: 'InfraSubnet'
    addressPrefix: '10.0.2.0/24'
  }
  {
    name: 'PrivateEndpointSubnet'
    addressPrefix: '10.0.3.0/24'
  }
]
param spokeVnetAddressPrefix string = '10.1.0.0/16'
param spokeSubnets array = [
  {
    name: 'AKSSubnet'
    addressPrefix: '10.1.0.0/24'
  }
  {
    name: 'DataSubnet'
    addressPrefix: '10.1.1.0/24'
  }
]
param sqlAdminPassword string = 'M1cr0soft'
param kvAdminUserObjectId string = '57963f10-818b-406d-a2f6-6e758d86e259'

var namingPrefix = '${prefix}-${uniqueString(resourceGroup().id)}'
var hubVnetName = 'hub-vnet-${namingPrefix}'
var spokeVnetName = 'spoke-vnet-${namingPrefix}'
var azFirewallName = 'az-fw-${namingPrefix}'
var azFirewallPublicIpName = 'az-fw-pip-${namingPrefix}'
var vpnGatewayName = 'vpn-gw-${namingPrefix}'
var gwyPublicIpAddressName = 'vpn-gw-pip-${namingPrefix}'
var storageAccountName = 'stor${prefix}${uniqueString(resourceGroup().id)}'
var sqlPrivateDNSZoneName = 'privatelink.database.windows.net'
var blobPrivateDNSZoneName = 'privatelink.blob.core.windows.net'
var kvPrivateDNSZoneName = 'privatelink.vaultcore.azure.net'
var sqlServerName = 'sql-server-${namingPrefix}'
var sqlAdminLogin = 'dbadmin'
var sqlDbName = 'AdventureWorksLT'
var keyVaultName = 'kv${prefix}${uniqueString(resourceGroup().id)}'
var azFirewallPolicyName = 'azFirewallPolicy1'

// vnets
module hubVnetModule './modules/vnet.bicep' = {
  name: hubVnetName
  params: {
    vnetName: hubVnetName
    subnets: hubSubnets
    vnetAddressPrefix: hubVnetAddressPrefix
  }
}

module spokeVnetModule './modules/vnet.bicep' = {
  name: spokeVnetName
  params: {
    vnetName: spokeVnetName
    subnets: spokeSubnets
    vnetAddressPrefix: spokeVnetAddressPrefix
  }
}

// vnet peerings
module vnetPeeringModule './modules/peering.bicep' = {
  name: 'vnetpeering'
  params: {
    localVnetId: hubVnetModule.outputs.id
    localVnetName: hubVnetModule.outputs.vnetName
    localVnetFriendlyName: 'hub-vnet'
    remoteVnetId: spokeVnetModule.outputs.id
    remoteVnetName: spokeVnetModule.outputs.vnetName
    remoteVnetFriendlyName: 'spoke-vnet'
  }
}

// az firewall & DNS proxy
resource azFirewallPublicIp 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  location: resourceGroup().location
  name: azFirewallPublicIpName
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource ipGroup 'Microsoft.Network/ipGroups@2020-11-01' = {
  location: resourceGroup().location
  name: 'privateIpGroup'
  properties: {
    ipAddresses: [
      '10.0.0.0/16'
      '10.1.0.0/16'
      '192.168.88.0/24'
    ]
  }
}

resource azFirewallPolicy 'Microsoft.Network/firewallPolicies@2020-05-01' = {
  name: azFirewallPolicyName
  location: resourceGroup().location
  tags: {}
  properties: {
    dnsSettings: {
      enableProxy: true
    }
  }
}

resource azFirewall 'Microsoft.Network/azureFirewalls@2020-11-01' = {
  location: resourceGroup().location
  name: azFirewallName
  zones: length(availabilityZones) == 0 ? json('null') : availabilityZones
  properties: {
    firewallPolicy: {
      id: azFirewallPolicy.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', hubVnetModule.outputs.vnetName, hubVnetModule.outputs.subnetArray[1].name)
          }
          publicIPAddress: {
            id: azFirewallPublicIp.id
          }
        }
      }
    ]
  }
}

resource azFirewallNetworkRuleGroup 'Microsoft.Network/firewallPolicies/ruleCollectionGroups@2020-11-01' = {
  name: '${azFirewallPolicy.name}/network-rule-group-1'
  properties: {
    priority: 1000
    ruleCollections: [
      {
        ruleCollectionType: 'FirewallPolicyFilterRuleCollection'
        name: 'network-rule-1'
        action: {
          type: 'Allow'
        }
        rules: [
          {
            name: 'allow_all_local_subnets'
            ruleType: 'NetworkRule'
            description: 'allow_all_local_subnets'
            sourceIpGroups: [
              ipGroup.id
            ]
            destinationIpGroups: [
              ipGroup.id
            ]
            destinationPorts: [
              '*'
            ]
            ipProtocols: [
              'Any'
            ]
          }
        ]
      }
    ]
  }
}

/* resource hubVirtualNetworkUpdate 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: hubVnetName
  location: resourceGroup().location
  properties: {
    dhcpOptions: {
      dnsServers: [
        azFirewall.properties.ipConfigurations[0].properties.privateIPAddress
      ]
    }
  }
}

resource spokeVirtualNetworkUpdate 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: spokeVnetName
  location: resourceGroup().location
  properties: {
    dhcpOptions: {
      dnsServers: [
        azFirewall.properties.ipConfigurations[0].properties.privateIPAddress
      ]
    }
  }
} */

resource localNetworkGateway 'Microsoft.Network/localNetworkGateways@2020-11-01' = {
  name: 'localGateway'
  location: resourceGroup().location
  properties: {
    gatewayIpAddress: localGatewayIpAddress
    localNetworkAddressSpace: {
      addressPrefixes: [
        '192.168.88.0/24'
      ]
    }
  }
}

resource gwyPublicIpAddress 'Microsoft.Network/publicIPAddresses@2020-11-01' = {
  location: resourceGroup().location
  name: gwyPublicIpAddressName
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  zones: [
    '1'
    '2'
    '3'
  ]
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

// az vpn gateway
resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2020-11-01' = {
  location: resourceGroup().location
  name: vpnGatewayName
  properties: {
    gatewayType: 'Vpn'
    sku: {
      name: 'VpnGw2AZ'
      tier: 'VpnGw2AZ'
    }
    vpnGatewayGeneration: 'Generation2'
    vpnType: 'RouteBased'
    ipConfigurations: [
      {
        name: 'gwyipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: gwyPublicIpAddress.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', hubVnetModule.outputs.vnetName, hubVnetModule.outputs.subnetArray[0].name)
          }
        }
      }
    ]
  }
}

resource vpnGwyConnection 'Microsoft.Network/connections@2020-11-01' = {
  name: 's2scxn'
  location: resourceGroup().location
  properties: {
    connectionType: 'IPsec'
    virtualNetworkGateway1: {
      id: vpnGateway.id
      properties: {}
    }
    sharedKey: vpnSharedSecret
    localNetworkGateway2: {
      id: localNetworkGateway.id
      properties: {}
    }
  }
}

// az storage + pl + dns zone
resource blobStorageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    allowBlobPublicAccess: true
    supportsHttpsTrafficOnly: true
    networkAcls: {
      defaultAction: 'Deny'
    }
  }
}

resource blobPrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  location: resourceGroup().location
  name: 'blobPrivateEndpoint'
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', hubVnetModule.outputs.vnetName, hubVnetModule.outputs.subnetArray[3].name)
    }
    privateLinkServiceConnections: [
      {
        name: 'blobStorageConnection'
        properties: {
          groupIds: [
            'Blob'
          ]
          privateLinkServiceId: blobStorageAccount.id
        }
      }
    ]
  }
}

// key vault + private endpoint
resource keyVault 'Microsoft.KeyVault/vaults@2019-09-01' = {
  location: resourceGroup().location
  name: keyVaultName
  properties: {
    enableSoftDelete: true
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: subscription().tenantId
    accessPolicies: [
      {
        objectId: kvAdminUserObjectId
        tenantId: subscription().tenantId
        permissions: {
          secrets: [
            'all'
          ]
        }
      }
    ]
  }
}

resource kvPrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  location: resourceGroup().location
  name: 'kvPrivateEndpoint'
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', hubVnetModule.outputs.vnetName, hubVnetModule.outputs.subnetArray[3].name)
    }
    privateLinkServiceConnections: [
      {
        name: 'kvConnection'
        properties: {
          groupIds: [
            'Vault'
          ]
          privateLinkServiceId: keyVault.id
        }
      }
    ]
  }
}

resource kvPrivateEndpointDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location: 'global'
  name: kvPrivateDNSZoneName
  properties: {}
}

resource blobPrivateEndpointDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location: 'global'
  name: blobPrivateDNSZoneName
  properties: {}
}

resource sqlPrivateEndpointDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  location: 'global'
  name: sqlPrivateDNSZoneName
  properties: {}
}

// as sql + pl + dns zone
resource sqlServer 'Microsoft.Sql/servers@2020-11-01-preview' = {
  location: resourceGroup().location
  name: sqlServerName
  properties: {
    //publicNetworkAccess: 'Disabled'
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
  }
}

resource sqlDb 'Microsoft.Sql/servers/databases@2020-11-01-preview' = {
  location: resourceGroup().location
  name: '${sqlServer.name}/${sqlDbName}'
  sku: {
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {
    sampleName: 'AdventureWorksLT'
  }
}

resource sqlPrivateEndpoint 'Microsoft.Network/privateEndpoints@2020-11-01' = {
  location: resourceGroup().location
  name: 'sqlPrivateEndpoint'
  properties: {
    subnet: {
      id: resourceId('Microsoft.Network/virtualNetworks/subnets', hubVnetModule.outputs.vnetName, hubVnetModule.outputs.subnetArray[3].name)
    }
    privateLinkServiceConnections: [
      {
        name: 'sqlConnection'
        properties: {
          groupIds: [
            'sqlServer'
          ]
          privateLinkServiceId: sqlServer.id
        }
      }
    ]
  }
}

resource virtualNetworkKVDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${kvPrivateEndpointDnsZone.name}/${kvPrivateEndpointDnsZone.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hubVnetModule.outputs.id
    }
  }
}

resource virtualNetworkBlobDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${blobPrivateEndpointDnsZone.name}/${blobPrivateEndpointDnsZone.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hubVnetModule.outputs.id
    }
  }
}

resource virtualNetworkSqlDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${sqlPrivateEndpointDnsZone.name}/${sqlPrivateEndpointDnsZone.name}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hubVnetModule.outputs.id
    }
  }
}

resource kvPrivateEndpointDnsARecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '${kvPrivateEndpointDnsZone.name}/${keyVault.name}'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: kvPrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
      }
    ]
  }
}

resource blobPrivateEndpointDnsARecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '${blobPrivateEndpointDnsZone.name}/${blobStorageAccount.name}'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: blobPrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
      }
    ]
  }
}

resource sqlPrivateEndpointDnsARecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '${sqlPrivateEndpointDnsZone.name}/${sqlServer.name}'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: sqlPrivateEndpoint.properties.customDnsConfigs[0].ipAddresses[0]
      }
    ]
  }
}

/* 
resource testVmStorageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  location: resourceGroup().location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  name: 'testvmstor239869234'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
  }
}

module testVm 'modules/vm.bicep' = {
  name: 'test-vm'
  params: {
    dataDiskCaching: 'ReadOnly'
    dataDiskSize: 128
    vmSize: 'Standard_B2s'
    location: resourceGroup().location
    name: 'test-vm'
    nsgName: 'test-vm-nsg'
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', hubVnetModule.outputs.vnetName, hubVnetModule.outputs.subnetArray[2].name)
    vmAdminUsername: 'localadmin'
    vmAdminPasswordOrKey: sshKey
    osDiskSize: 128
    storageAccount: testVmStorageAccount
    vmImage: {
      publisher: 'Canonical'
      offer: 'UbuntuServer'
      sku: '18.04-LTS'
      version: 'latest'
    }
    authenticationType: 'ssh'
    diskStorageAccountType: 'Standard_LRS'
  }
}
*/
