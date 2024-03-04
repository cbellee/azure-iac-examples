param location string = 'australiaeast'
param prefix string = 'contoso'
param workloadProfile bool = false
param imageName string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
param mTlsEnabled bool = false
param localGatewayIpAddress string
param vpnSharedKey string
param localNetworkAddressPrefixes array = [
  '192.168.88.0/24'
]

var suffix = uniqueString(resourceGroup().id)
var hubVnetName = '${prefix}-hub-vnet-${suffix}'
var spokeVnetName = '${prefix}-spoke-vnet-${suffix}'
var frontDoorName = '${prefix}-afd-${suffix}'
var wafPolicyName = '${prefix}wafpolicy'
var workspaceName = '${prefix}-wks-${suffix}'
var appName = '${prefix}-app-${suffix}'
var plsName = '${prefix}-pls-${suffix}'
var appEnvironmentName = '${prefix}-env-${suffix}'
var originName = '${prefix}-origin-${suffix}'
var originGroupName = '${prefix}-origin-group-${suffix}'
var afdEndpointName = '${prefix}-afd-ep-${suffix}'
var loadBalancerName = 'kubernetes-internal'
var worloadProfileLoadBalancerName = 'capp-svc-lb'
var defaultDomainArr = split(appEnvironment.properties.defaultDomain, '.')
var appEnvironmentResourceGroupName = 'MC_${defaultDomainArr[0]}-rg_${defaultDomainArr[0]}_${defaultDomainArr[1]}'
var vpnCxnName = 'vpn-cxn'
var localNetworkGatewayName = '${prefix}-local-gwy-${suffix}'
var vpnGatewayPublicIpAddressName = '${prefix}-vpn-gwy-pip-${suffix}'
var virtualNetworkGatewayName = '${prefix}-vpn-gwy-${suffix}'

var delegation = [
  {
    name: 'app-environment-delegation'
    properties: {
      serviceName: 'Microsoft.App/environments'
    }
  }
]

var profiles = [
  {
    name: 'dedicated-d4'
    workloadProfileType: 'D8'
    minimumCount: 0
    maximumCount: 3
  }
  {
    name: 'dedicated-e4'
    workloadProfileType: 'E8'
    minimumCount: 0
    maximumCount: 3
  }
]

resource hubVnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: hubVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.0.0.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'inbound-dns-subnet'
        properties: {
          addressPrefix: '10.0.1.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'outbound-dns-subnet'
        properties: {
          addressPrefix: '10.0.2.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

resource spokeVnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: spokeVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'infrastructure-subnet'
        properties: {
          addressPrefix: '10.1.0.0/23'
          delegations: workloadProfile ? delegation : null
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'privatelinkservice-subnet'
        properties: {
          addressPrefix: '10.1.3.0/24'
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
    ]
    enableDdosProtection: false
  }
}

resource hubToSpokePeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  name: 'hub-to-spoke'
  parent: hubVnet
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    allowVirtualNetworkAccess: true
    remoteVirtualNetwork: {
      id: spokeVnet.id
    }
  }
}

resource SpokeToHubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-04-01' = {
  name: 'spoke-to-hub'
  parent: spokeVnet
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: true
    allowVirtualNetworkAccess: true
    useRemoteGateways: true
    remoteVirtualNetwork: {
      id: hubVnet.id
    }
  }
}

resource localNetworkGateway 'Microsoft.Network/localNetworkGateways@2023-04-01' = {
  name: localNetworkGatewayName
  location: location
  properties: {
    gatewayIpAddress: localGatewayIpAddress
    localNetworkAddressSpace: {
      addressPrefixes: localNetworkAddressPrefixes
    }
  }
}

resource gatewayPublicIpAddress 'Microsoft.Network/publicIPAddresses@2023-04-01' = {
  name: vpnGatewayPublicIpAddressName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
}

resource virtualNetworkGateway 'Microsoft.Network/virtualNetworkGateways@2023-04-01' = {
  name: virtualNetworkGatewayName
  location: location
  properties: {
    gatewayType: 'Vpn'
    sku: {
      name: 'VpnGw2'
      tier: 'VpnGw2'
    }
    vpnType: 'RouteBased'
    vpnGatewayGeneration: 'Generation2'
    ipConfigurations: [
      {
        name: 'default'
        properties: {
          subnet: {
            id: hubVnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: gatewayPublicIpAddress.id
          }
        }
      }
    ]
  }
}

resource virtualNetworkGatewayCxn 'Microsoft.Network/connections@2023-04-01' = {
  name: vpnCxnName
  location: location
  properties: {
    virtualNetworkGateway1: {
      properties: {
        allowRemoteVnetTraffic: true
      }
      id: virtualNetworkGateway.id
    }
    localNetworkGateway2: {
      properties: {}
      id: localNetworkGateway.id
    }
    connectionType: 'IPsec'
    connectionProtocol: 'IKEv2'
    sharedKey: vpnSharedKey
    routingWeight: 0
    enableBgp: false
    dpdTimeoutSeconds: 45
    connectionMode: 'Default'
  }
}

resource wks 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'pergb2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource appEnvironment 'Microsoft.App/managedEnvironments@2023-05-01' = {
  name: appEnvironmentName
  location: location
  properties: {
    workloadProfiles: workloadProfile ? profiles : null
    peerAuthentication: {
      mtls: {
        enabled: mTlsEnabled
      }
    }
    vnetConfiguration: {
      internal: true
      infrastructureSubnetId: spokeVnet.properties.subnets[0].id
    }
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: wks.properties.customerId
        sharedKey: wks.listKeys().primarySharedKey
      }
    }
    zoneRedundant: false
  }
}

resource containerApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: appName
  location: location
  identity: {
    type: 'None'
  }
  properties: {
    workloadProfileName: workloadProfile ? profiles[1].name : null
    environmentId: appEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 80
        exposedPort: 0
        transport: 'Auto'
        traffic: [
          {
            weight: 50
            latestRevision: true
          }
        ]
        allowInsecure: false
      }
    }
    template: {
      containers: [
        {
          image: imageName
          name: appName
          resources: {
            cpu: '0.25'
            memory: '0.5Gi'
          }
        }
      ]
      scale: {
        maxReplicas: 10
      }
    }
  }
}

module privateLinkService './modules/pls.bicep' = {
  name: 'modules-private-link-service'
  params: {
    appEnvironmentManagedResourceGroupName: workloadProfile ? appEnvironment.properties.infrastructureResourceGroup : appEnvironmentResourceGroupName
    loadBalancerName: workloadProfile ? worloadProfileLoadBalancerName : loadBalancerName
    location: location
    name: plsName
    subnetId: spokeVnet.properties.subnets[1].id
    remoteSubscriptionId: 
    subscriptionId: subscription().subscriptionId
  }
}

resource frontDoor 'Microsoft.Cdn/profiles@2023-05-01' = {
  name: frontDoorName
  location: 'Global'
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
  properties: {
    originResponseTimeoutSeconds: 30
  }
}

resource afdOriginGroup 'Microsoft.Cdn/profiles/originGroups@2023-05-01' = {
  parent: frontDoor
  name: originGroupName
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 50
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'GET'
      probeProtocol: 'Https'
      probeIntervalInSeconds: 60
    }
    sessionAffinityState: 'Disabled'
  }
}

resource afdEndpoint 'Microsoft.Cdn/profiles/afdEndpoints@2023-05-01' = {
  parent: frontDoor
  name: afdEndpointName
  location: 'Global'
  properties: {
    autoGeneratedDomainNameLabelScope: 'TenantReuse'
    enabledState: 'Enabled'
  }
}

resource afdRoute 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-05-01' = {
  parent: afdEndpoint
  name: 'route'
  properties: {
    customDomains: []
    originGroup: {
      id: afdOriginGroup.id
    }
    originPath: '/'
    ruleSets: []
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    forwardingProtocol: 'MatchRequest'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
    enabledState: 'Enabled'
  }
  dependsOn: [
    afdOrigin
  ]
}

resource afdOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2023-05-01' = {
  parent: afdOriginGroup
  name: originName
  properties: {
    hostName: containerApp.properties.configuration.ingress.fqdn
    httpPort: 80
    httpsPort: 443
    originHostHeader: containerApp.properties.configuration.ingress.fqdn
    priority: 1
    weight: 50
    enabledState: 'Enabled'
    sharedPrivateLinkResource: {
      privateLink: {
        id: privateLinkService.outputs.id
      }
      privateLinkLocation: location
      status: 'Approved'
      requestMessage: 'Please approve this request to allow Front Door to access the container app'
    }
    enforceCertificateNameCheck: true
  }
}

resource wafPolicy 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2022-05-01' = {
  name: wafPolicyName
  location: 'Global'
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
  properties: {
    policySettings: {
      enabledState: 'Enabled'
      mode: 'Prevention'
      requestBodyCheck: 'Enabled'
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'Microsoft_DefaultRuleSet'
          ruleSetVersion: '1.1'
          ruleGroupOverrides: []
          exclusions: []
        }
        {
          ruleSetType: 'Microsoft_BotManagerRuleSet'
          ruleSetVersion: '1.0'
          ruleGroupOverrides: []
          exclusions: []
        }
      ]
    }
  }
}

resource afdSecurityPolicy 'Microsoft.Cdn/profiles/securityPolicies@2023-05-01' = {
  parent: frontDoor
  name: '${prefix}-default-security-policy'
  properties: {
    parameters: {
      wafPolicy: {
        id: wafPolicy.id
      }
      associations: [
        {
          domains: [
            {
              id: afdEndpoint.id
            }
          ]
          patternsToMatch: [
            '/*'
          ]
        }
      ]
      type: 'WebApplicationFirewall'
    }
  }
}

output afdFqdn string = afdEndpoint.properties.hostName
output privateLinkServiceName string = privateLinkService.outputs.name
output containerAppFqdn string = containerApp.properties.configuration.ingress.fqdn
output containerAppEnvironmentPrivateIpAddress string = appEnvironment.properties.staticIp
