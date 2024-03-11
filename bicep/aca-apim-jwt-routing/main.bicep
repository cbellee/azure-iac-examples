param location string
param acrName string
param containerAppName string = 'colourapp'
param containerImageName string
param containerImageTag string = 'latest'
param publisherEmail string = 'me@home.net'
param publisherName string = 'me'
param addressPrefix string = '10.1.0.0/16'
param version string
param betaTenantName string
param validIssuers string

var suffix = uniqueString(resourceGroup().id)
var containerAppEnvName = 'acaenv-${suffix}'
var uamiName = 'acr-pull-umid-${suffix}'
var apimName = 'apim-${suffix}'
var vnetName = 'vnet-${suffix}'
var vipName = 'vip-${suffix}'
var domainNameLabel = 'apim-${suffix}'

var greenAppFqdn = containerAppGreen.properties.configuration.ingress.fqdn
var blueAppFqdn = containerAppBlue.properties.configuration.ingress.fqdn

var content = loadTextContent('./policies/apim-policy-template.xml')
var policy = replace(replace(replace(replace(content, '{0}', betaTenantName), '{1}', blueAppFqdn), '{2}', greenAppFqdn), '{3}', validIssuers)

var acaSubnetAddress = cidrSubnet(addressPrefix, 22, 0)
var apimSubnetAddress = cidrSubnet(cidrSubnet(addressPrefix, 22, 1), 24, 0)
var appGwySubnetAddress = cidrSubnet(cidrSubnet(addressPrefix, 22, 1), 24, 1)
var mgmtSubnetAddress = cidrSubnet(cidrSubnet(addressPrefix, 22, 1), 24, 2)
var bastionSubnetAddress = cidrSubnet(cidrSubnet(addressPrefix, 22, 1), 24, 3)

var acrPullRoleId = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

resource acrPullRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: acrPullRoleId
}

resource apimNSG 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'apim-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'apim-client-comms'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 1900
          protocol: 'Tcp'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationPortRanges: [
            '80'
            '443'
          ]
        }
      }
      {
        name: 'apim-client-internal-comms'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          priority: 1910
          protocol: 'Tcp'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          sourcePortRange: '*'
          destinationPortRanges: [
            '80'
            '443'
          ]
        }
      }
      {
        name: 'apim-mgmt-endpoint-for-portal'
        properties: {
          priority: 2000
          sourceAddressPrefix: 'ApiManagement'
          protocol: 'Tcp'
          destinationPortRange: '3443'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      {
        name: 'apim-azure-infra-lb'
        properties: {
          priority: 2010
          sourceAddressPrefix: 'AzureLoadBalancer'
          protocol: 'Tcp'
          destinationPortRange: '6390'
          access: 'Allow'
          direction: 'Inbound'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
      {
        name: 'apim-azure-storage'
        properties: {
          priority: 2000
          sourceAddressPrefix: 'VirtualNetwork'
          protocol: 'Tcp'
          destinationPortRange: '443'
          access: 'Allow'
          direction: 'Outbound'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Storage'
        }
      }
      {
        name: 'apim-azure-sql'
        properties: {
          priority: 2010
          sourceAddressPrefix: 'VirtualNetwork'
          protocol: 'Tcp'
          destinationPortRange: '1433'
          access: 'Allow'
          direction: 'Outbound'
          sourcePortRange: '*'
          destinationAddressPrefix: 'SQL'
        }
      }
      {
        name: 'apim-azure-kv'
        properties: {
          priority: 2020
          sourceAddressPrefix: 'VirtualNetwork'
          protocol: 'Tcp'
          destinationPortRange: '443'
          access: 'Allow'
          direction: 'Outbound'
          sourcePortRange: '*'
          destinationAddressPrefix: 'AzureKeyVault'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: 'apim-subnet'
        properties: {
          addressPrefix: apimSubnetAddress
          networkSecurityGroup: {
            id: apimNSG.id
          }
        }
      }
      {
        name: 'aca-subnet'
        properties: {
          addressPrefix: acaSubnetAddress
        }
      }
      {
        name: 'appgwy-subnet'
        properties: {
          addressPrefix: appGwySubnetAddress
        }
      }
      {
        name: 'mgmt-subnet'
        properties: {
          addressPrefix: mgmtSubnetAddress
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: bastionSubnetAddress
        }
      }
    ]
  }
}

module wks 'modules/wks.bicep' = {
  name: 'wks-module'
  params: {
    location: location
  }
}

module bastion 'modules/bastion.bicep' = {
  name: 'bastion-module'
  params: {
    location: location
    vnetId: vnet.id
    subnetId: vnet.properties.subnets[4].id
  }
}

resource apimVip 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: vipName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: domainNameLabel
    }
  }
}

module appGwy 'modules/appGateway.bicep' = {
  name: 'appGwy-module'
  params: {
    location: location
    gatewaySku: 'WAF_v2'
    probePath: '/status-0123456789abcdef'
    subnetId: vnet.properties.subnets[2].id
    userAssignedManagedIdentityId: userAssignedManagedIdentity.id
    hostName: replace(apim.properties.gatewayUrl, 'https://', '')
    backendHttpPort: 443
  }
}

resource apim 'Microsoft.ApiManagement/service@2023-05-01-preview' = {
  name: apimName
  location: location
  sku: {
    name: 'Developer'
    capacity: 1
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    virtualNetworkConfiguration: {
      subnetResourceId: vnet.properties.subnets[0].id
    }
    virtualNetworkType: 'Internal'
    publicIpAddressId: apimVip.id
  }
}

/* resource applicationInsightsApiLogger 'Microsoft.ApiManagement/service/apis/diagnostics/loggers@2018-01-01' = {
  parent: applicationInsights
  name: 'app-insights-logger-${suffix}'
}

resource apimLogger 'Microsoft.ApiManagement/service/loggers@2023-05-01-preview' = {
  parent: apim
  name: 'app-insights-logger-${suffix}'
  properties: {
    loggerType: 'applicationInsights'
    credentials: {
      instrumentationKey:  // '{{Logger-Credentials--65ebf9ba217d201e60ec0b4a}}'
    }
    isBuffered: true
    resourceId: applicationInsights.id
  }
}

resource apim_7jr2alf4jk5bw_azuremonitor 'Microsoft.ApiManagement/service/loggers@2023-05-01-preview' = {
  parent: apim
  name: 'azuremonitor'
  properties: {
    loggerType: 'azureMonitor'
    isBuffered: true
  }
}

resource applicationInsights 'Microsoft.ApiManagement/service/apis/diagnostics@2023-05-01-preview' = {
  parent: colourApp
  name: 'applicationinsights'
  properties: {
    alwaysLog: 'allErrors'
    httpCorrelationProtocol: 'Legacy'
    verbosity: 'information'
    logClientIp: true
    loggerId: resourceId('Microsoft.ApiManagement/service/apis/diagnostics/loggers', 'app-insights-logger-${suffix}') //applicationinsightslogger.id
    sampling: {
      samplingType: 'fixed'
      percentage: 100
    }
    frontend: {
      request: {
        headers: []
        body: {
          bytes: 0
        }
      }
      response: {
        headers: []
        body: {
          bytes: 0
        }
      }
    }
    backend: {
      request: {
        headers: []
        body: {
          bytes: 0
        }
      }
      response: {
        headers: []
        body: {
          bytes: 0
        }
      }
    }
  }
} */

resource colourApp 'Microsoft.ApiManagement/service/apis@2023-05-01-preview' = {
  parent: apim
  name: 'colourapp'
  properties: {
    displayName: 'colourapp'
    apiRevision: '1'
    subscriptionRequired: false
    path: 'colourapp'
    protocols: [ 'https' ]
  }
}

resource colourAppGet 'Microsoft.ApiManagement/service/apis/operations@2023-05-01-preview' = {
  parent: colourApp
  name: '65ebc90ebb313969c6969f12'
  properties: {
    displayName: 'colourapp_GET'
    method: 'GET'
    urlTemplate: '/*'
    templateParameters: []
    responses: []
  }
}

resource colourAppPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-05-01-preview' = {
  parent: colourApp
  name: 'policy'
  properties: {
    value: policy
    format: 'rawxml'
  }
}

resource colourAppBlue 'Microsoft.ApiManagement/service/backends@2023-05-01-preview' = {
  parent: apim
  name: 'colourapp-blue'
  properties: {
    description: 'colourapp-blue'
    url: 'https://${containerAppBlue.properties.configuration.ingress.fqdn}'
    protocol: 'http'
  }
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-08-01-preview' existing = {
  name: acrName
}

resource userAssignedManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: uamiName
  location: location
}

resource containerAppEnv 'Microsoft.App/managedEnvironments@2023-08-01-preview' = {
  name: containerAppEnvName
  location: location
  properties: {
    vnetConfiguration: {
      infrastructureSubnetId: vnet.properties.subnets[1].id
      internal: true
    }
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: wks.outputs.customerId
        sharedKey: wks.outputs.sharedKey
      }
    }
  }
}

module dnsZone 'modules/dnsZone.bicep' = {
  name: 'module-dnszone-${location}'
  params: {
    acaEnvironmentDomainName: containerAppEnv.properties.defaultDomain
    acaIlbIpAddress: containerAppEnv.properties.staticIp
    dnsZoneName: '${location}.azurecontainerapps.io'
    vnetName: vnet.name
  }
}

resource acrRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, userAssignedManagedIdentity.id, acr.id)
  scope: acr
  properties: {
    roleDefinitionId: acrPullRole.id
    principalId: userAssignedManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource containerAppBlue 'Microsoft.App/containerApps@2023-08-01-preview' = {
  name: '${containerAppName}-blue'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedManagedIdentity.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    environmentId: containerAppEnv.id
    configuration: {
      ingress: {
        targetPort: 80
        external: true
      }
      registries: [
        {
          identity: userAssignedManagedIdentity.id
          server: '${acr.name}.azurecr.io'
        }
      ]
    }
    template: {
      containers: [
        {
          image: '${containerImageName}:${containerImageTag}'
          name: containerAppName
          env: [
            {
              name: 'COLOUR'
              value: 'blue'
            }
            {
              name: 'VERSION'
              value: version
            }
          ]
        }
      ]
    }
  }
  dependsOn: [
    acrRoleAssignment
  ]
}

resource containerAppGreen 'Microsoft.App/containerApps@2023-08-01-preview' = {
  name: '${containerAppName}-green'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userAssignedManagedIdentity.id}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppEnv.id
    environmentId: containerAppEnv.id
    configuration: {
      ingress: {
        targetPort: 80
        external: true
      }
      registries: [
        {
          identity: userAssignedManagedIdentity.id
          server: '${acr.name}.azurecr.io'
        }
      ]
    }
    template: {
      containers: [
        {
          image: '${containerImageName}:${containerImageTag}'
          name: containerAppName
          env: [
            {
              name: 'COLOUR'
              value: 'green'
            }
            {
              name: 'VERSION'
              value: version
            }
          ]
        }
      ]
    }
  }
  dependsOn: [
    acrRoleAssignment
  ]
}

output blueAppFqdn string = containerAppBlue.properties.configuration.ingress.fqdn
output greenAppFqdn string = containerAppGreen.properties.configuration.ingress.fqdn
output appGwyIp string = appGwy.outputs.appGatewayFrontEndIpAddress
