param location string = 'australiaeast'
param prefix string = 'contoso'
param imageName string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'

var suffix = uniqueString(resourceGroup().id)
var vnetName = '${prefix}-vnet-${suffix}'
var frontDoorName = '${prefix}-afd-${suffix}'
var wafPolicyName = '${prefix}wafpolicy'
var workspaceName = '${prefix}-wks-${suffix}'
var appName = '${prefix}-app-${suffix}'
var appName2 = '${prefix}-app-${suffix}-2'
var plsName = '${prefix}-pls-${suffix}'
var appEnvironmentName = '${prefix}-env-${suffix}'
var originName = '${prefix}-origin-${suffix}'
var originName2 = '${prefix}-origin-${suffix}-2'
var originGroupName = '${prefix}-origin-group-${suffix}'
var originGroupName2 = '${prefix}-origin-group-${suffix}-2'
var afdEndpointName = '${prefix}-afd-ep-${suffix}'
var loadBalancerName = 'kubernetes-internal'
var defaultDomainArr = split(appEnvironment.properties.defaultDomain, '.')
var appEnvironmentResourceGroupName = 'mc_${defaultDomainArr[0]}-rg_${defaultDomainArr[0]}_${defaultDomainArr[1]}'

resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'infrastructure-subnet'
        properties: {
          addressPrefix: '10.0.0.0/23'
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'privatelinkservice-subnet'
        properties: {
          addressPrefix: '10.0.2.0/28'
          delegations: []
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Disabled'
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource wks 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
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

resource appEnvironment 'Microsoft.App/managedEnvironments@2022-06-01-preview' = {
  name: appEnvironmentName
  location: location
  sku: {
    name: 'Consumption'
  }
  properties: {
    vnetConfiguration: {
      internal: true
      infrastructureSubnetId: vnet.properties.subnets[0].id
      dockerBridgeCidr: '10.2.0.1/16'
      platformReservedCidr: '10.1.0.0/16'
      platformReservedDnsIP: '10.1.0.2'
      outboundSettings: {
        outBoundType: 'LoadBalancer'
      }
    }
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: wks.properties.customerId
        sharedKey: listKeys(wks.id, wks.apiVersion).primarySharedKey
      }
    }
    zoneRedundant: false
  }
}

resource containerApp 'Microsoft.App/containerApps@2022-06-01-preview' = {
  name: appName
  location: location
  identity: {
    type: 'None'
  }
  properties: {
    managedEnvironmentId: appEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 80
        exposedPort: 0
        transport: 'Auto'
        traffic: [
          {
            weight: 100
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

resource containerApp2 'Microsoft.App/containerApps@2022-06-01-preview' = {
  name: appName2
  location: location
  identity: {
    type: 'None'
  }
  properties: {
    managedEnvironmentId: appEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 80
        exposedPort: 0
        transport: 'Auto'
        traffic: [
          {
            weight: 100
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
          name: '${appName}-2'
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
    appEnvironmentResourceGroupName: appEnvironmentResourceGroupName
    loadBalancerName: loadBalancerName
    location: location
    name: plsName
    subnetId: vnet.properties.subnets[1].id
  }
}

resource frontDoor 'Microsoft.Cdn/profiles@2022-11-01-preview' = {
  name: frontDoorName
  location: 'Global'
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
  properties: {
    originResponseTimeoutSeconds: 30
    extendedProperties: {
    }
  }
}

resource afdOriginGroup 'Microsoft.Cdn/profiles/origingroups@2022-11-01-preview' = {
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

resource afdOriginGroup2 'Microsoft.Cdn/profiles/origingroups@2022-11-01-preview' = {
  parent: frontDoor
  name: originGroupName2
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


resource afdEndpoint 'Microsoft.Cdn/profiles/afdendpoints@2022-11-01-preview' = {
  parent: frontDoor
  name: afdEndpointName
  location: 'Global'
  properties: {
    autoGeneratedDomainNameLabelScope: 'TenantReuse'
    enabledState: 'Enabled'
  }
}

resource afdEndpoint2 'Microsoft.Cdn/profiles/afdendpoints@2022-11-01-preview' = {
  parent: frontDoor
  name: '${afdEndpointName}-2'
  location: 'Global'
  properties: {
    autoGeneratedDomainNameLabelScope: 'TenantReuse'
    enabledState: 'Enabled'
  }
}

resource afdRoute 'Microsoft.Cdn/profiles/afdendpoints/routes@2022-11-01-preview' = {
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

resource afdRoute2 'Microsoft.Cdn/profiles/afdendpoints/routes@2022-11-01-preview' = {
  parent: afdEndpoint2
  name: 'route'
  properties: {
    customDomains: []
    originGroup: {
      id: afdOriginGroup2.id
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
    afdOrigin2
  ]
}

resource afdOrigin 'Microsoft.Cdn/profiles/origingroups/origins@2022-11-01-preview' = {
  parent: afdOriginGroup
  name: originName
  properties: {
    hostName: containerApp.properties.configuration.ingress.fqdn
    httpPort: 80
    httpsPort: 443
    originHostHeader: containerApp.properties.configuration.ingress.fqdn
    priority: 1
    weight: 1000
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

resource afdOrigin2 'Microsoft.Cdn/profiles/origingroups/origins@2022-11-01-preview' = {
  parent: afdOriginGroup2
  name: originName2
  properties: {
    hostName: containerApp2.properties.configuration.ingress.fqdn
    httpPort: 80
    httpsPort: 443
    originHostHeader: containerApp2.properties.configuration.ingress.fqdn
    priority: 1
    weight: 1000
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

resource afdSecurityPolicy 'Microsoft.Cdn/profiles/securitypolicies@2022-11-01-preview' = {
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
