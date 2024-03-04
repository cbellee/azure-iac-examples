param location string
param sshPublicKey string
param adminUserName string
param vmSku string = 'Standard_D4ds_v5'
param adminGroupId string = 'f6a900e2-df11-43e7-ba3e-22be99d3cede'

var affix = uniqueString(resourceGroup().id)
var bastionName = 'bastion-${affix}'
var bastionPipName = 'bastion-pip-${affix}'
var afdName = 'afd-${affix}'
var vnetName = 'vnet-${affix}'
var agcName = 'agc-${affix}'
var aksClusterName = 'aks-cluster-${affix}'

resource bastion_pip 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  name: bastionPipName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    ipAddress: '4.197.104.175'
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    ipTags: []
    ddosSettings: {
      protectionMode: 'VirtualNetworkInherited'
    }
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-06-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    encryption: {
      enabled: false
      enforcement: 'AllowUnencrypted'
    }
    subnets: [
      {
        name: 'alb-subnet'
        properties: {
          addressPrefixes: [
            '10.0.0.0/24'
          ]
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          defaultOutboundAccess: true
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.0.1.0/26'
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          defaultOutboundAccess: true
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      {
        name: 'aks-subnet'
        properties: {
          addressPrefixes: [
            '10.0.2.0/24'
          ]
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          defaultOutboundAccess: true
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
      {
        name: 'agc-subnet'
        properties: {
          addressPrefix: '10.0.3.0/24'
          serviceEndpoints: []
          delegations: [
            {
              name: 'Microsoft.ServiceNetworking.trafficControllers'
              properties: {
                serviceName: 'Microsoft.ServiceNetworking/trafficControllers'
              }
              type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            }
          ]
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets'
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource agc_subnet 'Microsoft.Network/virtualNetworks/subnets@2023-06-01' = {
  name: 'agc-subnet'
  parent: vnet
  properties: {
    addressPrefix: '10.0.3.0/24'
    serviceEndpoints: []
    delegations: [
      {
        name: 'Microsoft.ServiceNetworking.trafficControllers'
        properties: {
          serviceName: 'Microsoft.ServiceNetworking/trafficControllers'
        }
        type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
      }
    ]
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource aks_subnet 'Microsoft.Network/virtualNetworks/subnets@2023-06-01' = {
  name: 'aks-subnet'
  parent: vnet
  properties: {
    addressPrefixes: [
      '10.0.2.0/24'
    ]
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    defaultOutboundAccess: true
  }
}

resource alb_subnet 'Microsoft.Network/virtualNetworks/subnets@2023-06-01' = {
  name: 'alb-subnet'
  parent: vnet
  properties: {
    addressPrefixes: [
      '10.0.0.0/24'
    ]
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    defaultOutboundAccess: true
  }
}

resource AzureBastionSubnet 'Microsoft.Network/virtualNetworks/subnets@2023-06-01' = {
  name: 'AzureBastionSubnet'
  parent: vnet
  properties: {
    addressPrefix: '10.0.1.0/26'
    delegations: []
    privateEndpointNetworkPolicies: 'Disabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    defaultOutboundAccess: true
  }
}

resource aks_cluster 'Microsoft.ContainerService/managedClusters@2023-10-02-preview' = {
  name: aksClusterName
  location: location
  sku: {
    name: 'Base'
    tier: 'Free'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    kubernetesVersion: '1.28.3'
    dnsPrefix: 'afd-agc-aks-cluster-dns'
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: 2
        vmSize: vmSku
        osDiskSizeGB: 128
        osDiskType: 'Ephemeral'
        kubeletDiskType: 'OS'
        vnetSubnetID: aks_subnet.id
        maxPods: 110
        type: 'VirtualMachineScaleSets'
        maxCount: 5
        minCount: 2
        enableAutoScaling: true
        powerState: {
          code: 'Running'
        }
        orchestratorVersion: '1.28.3'
        enableNodePublicIP: false
        mode: 'System'
        osType: 'Linux'
        osSKU: 'Ubuntu'
        upgradeSettings: {
          maxSurge: '10%'
        }
        enableFIPS: false
        securityProfile: {
          sshAccess: 'LocalUser'
        }
      }
    ]
    linuxProfile: {
      adminUsername: adminUserName
      ssh: {
        publicKeys: [
          {
            keyData: sshPublicKey
          }
        ]
      }
    }
    servicePrincipalProfile: {
      clientId: 'msi'
    }
    addonProfiles: {
      azureKeyvaultSecretsProvider: {
        enabled: false
      }
      azurepolicy: {
        enabled: false
      }
    }
    enableRBAC: true
    supportPlan: 'KubernetesOfficial'

    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'calico'
      networkDataplane: 'azure'
      loadBalancerSku: 'Standard'
      loadBalancerProfile: {
        managedOutboundIPs: {
          count: 1
        }
        backendPoolType: 'nodeIPConfiguration'
      }
      serviceCidr: '192.168.0.0/16'
      dnsServiceIP: '192.168.0.10'
      outboundType: 'loadBalancer'
      serviceCidrs: [
        '192.168.0.0/16'
      ]
      ipFamilies: [
        'IPv4'
      ]
    }

    aadProfile: {
      managed: true
      enableAzureRBAC: true
      tenantID: tenant().tenantId
      adminGroupObjectIDs: [
        adminGroupId
      ]
    }
    autoScalerProfile: {
      'balance-similar-node-groups': 'false'
      'daemonset-eviction-for-empty-nodes': false
      'daemonset-eviction-for-occupied-nodes': true
      expander: 'random'
      'ignore-daemonsets-utilization': false
      'max-empty-bulk-delete': '10'
      'max-graceful-termination-sec': '600'
      'max-node-provision-time': '15m'
      'max-total-unready-percentage': '45'
      'new-pod-scale-up-delay': '0s'
      'ok-total-unready-count': '3'
      'scale-down-delay-after-add': '10m'
      'scale-down-delay-after-delete': '10s'
      'scale-down-delay-after-failure': '3m'
      'scale-down-unneeded-time': '10m'
      'scale-down-unready-time': '20m'
      'scale-down-utilization-threshold': '0.5'
      'scan-interval': '10s'
      'skip-nodes-with-local-storage': 'false'
      'skip-nodes-with-system-pods': 'true'
    }
    autoUpgradeProfile: {
      upgradeChannel: 'patch'
      nodeOSUpgradeChannel: 'NodeImage'
    }
    disableLocalAccounts: true
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
    storageProfile: {
      diskCSIDriver: {
        enabled: true
        version: 'v1'
      }
      fileCSIDriver: {
        enabled: true
      }
      snapshotController: {
        enabled: true
      }
    }
    oidcIssuerProfile: {
      enabled: true
    }
    workloadAutoScalerProfile: {}
    metricsProfile: {
      costAnalysis: {
        enabled: false
      }
    }
  }
}

resource aks_cluster_agentpool 'Microsoft.ContainerService/managedClusters/agentPools@2023-08-02-preview' = {
  parent: aks_cluster
  name: 'agentpool'
  properties: {
    count: 2
    vmSize: vmSku
    osDiskSizeGB: 128
    osDiskType: 'Ephemeral'
    kubeletDiskType: 'OS'
    vnetSubnetID: aks_subnet.id
    maxPods: 110
    type: 'VirtualMachineScaleSets'
    maxCount: 5
    minCount: 2
    enableAutoScaling: true
    powerState: {
      code: 'Running'
    }
    orchestratorVersion: '1.28.3'
    enableNodePublicIP: false
    mode: 'System'
    osType: 'Linux'
    osSKU: 'Ubuntu'
    upgradeSettings: {
      maxSurge: '10%'
    }
    enableFIPS: false
    securityProfile: {
      sshAccess: 'LocalUser'
    }
  }
}

resource agc 'Microsoft.ServiceNetworking/trafficControllers@2023-11-01' = {
  name: agcName
  location: location
  properties: {}
}

resource agc_frontend 'Microsoft.ServiceNetworking/trafficControllers/Frontends@2023-11-01' = {
  parent: agc
  name: 'frontend-1'
  location: location
}

resource agc_association 'Microsoft.ServiceNetworking/trafficControllers/Associations@2023-11-01' = {
  parent: agc
  name: 'assoc-1'
  location: location
  properties: {
    associationType: 'subnets'
    subnet: {
      id: agc_subnet.id
    }
  }
}

resource frontdoor 'Microsoft.Cdn/profiles@2022-11-01-preview' = {
  name: afdName
  location: 'Global'
  sku: {
    name: 'Standard_AzureFrontDoor'
  }
  properties: {
    originResponseTimeoutSeconds: 60
  }
}

resource frontdoor_endpoint 'Microsoft.Cdn/profiles/afdendpoints@2022-11-01-preview' = {
  parent: frontdoor
  name: 'endpoint-1'
  location: 'Global'
  properties: {
    enabledState: 'Enabled'
  }
}

resource frontdoor_origin_group 'Microsoft.Cdn/profiles/origingroups@2022-11-01-preview' = {
  parent: frontdoor
  name: 'origin-1'
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 50
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Http'
      probeIntervalInSeconds: 100
    }
    sessionAffinityState: 'Disabled'
  }
}

resource frontdoor_origin 'Microsoft.Cdn/profiles/origingroups/origins@2022-11-01-preview' = {
  parent: frontdoor_origin_group
  name: 'origin-1'
  properties: {
    hostName: agc_frontend.properties.fqdn
    httpPort: 80
    httpsPort: 443
    originHostHeader: agc_frontend.properties.fqdn
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
    enforceCertificateNameCheck: true
  }
}

resource frontdoor_route 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-07-01-preview' = {
  name: 'route-1'
  parent: frontdoor_endpoint
  properties: {
    enabledState: 'Enabled'
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'HttpOnly'
    httpsRedirect: 'Enabled'
    originGroup: {
      id: frontdoor_origin_group.id
    }
    originPath: '/'
    supportedProtocols: [
      'Https'
    ]
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-06-01' = {
  name: bastionName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    dnsName: 'bst-6d41c999-2b30-48b4-9376-0d721e2bcc69.bastion.azure.com'
    scaleUnits: 2
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: bastion_pip.id
          }
          subnet: {
            id: AzureBastionSubnet.id
          }
        }
      }
    ]
  }
}

output aks_cluster_id string = aks_cluster.id
output aks_cluster_name string = aks_cluster.name
output agc_id string = agc.id
output agc_name string = agc.name
output agc_frontend_name string = agc_frontend.name
output agc_subnet_id string = agc_subnet.id
