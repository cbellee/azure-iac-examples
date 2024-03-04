param originFqdn string
param location string = resourceGroup().location
param keyVaultName string
param externalDomainResourceGroupName string = 'external-dns-zones-rg'
param prefix string
param domainName string = 'bellee.net'
param certificateId string

var suffix = uniqueString(resourceGroup().id)
var afdName = '${prefix}-afd-${suffix}'
var workspaceName = '${prefix}-wks-${suffix}'
var diagnosticSettingsName = 'diagnosticSettings'
var keyVaultReaderRoleDefinitionId = '4633458b-17de-408a-b874-0445c86b69e6'

var logCategories = [
  'FrontDoorAccessLog'
  'FrontDoorHealthProbeLog'
  'FrontDoorWebApplicationFirewallLog'
]

var metricCategories = [
  'AllMetrics'
]

var logs = [for category in logCategories: {
  category: category
  enabled: true
}]

var metrics = [for category in metricCategories: {
  category: category
  enabled: true
}]

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: keyVaultName
}

resource wks 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
}

resource keyvault_rbac 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, keyVaultReaderRoleDefinitionId)
  scope: keyVault
  properties: {
    principalId: frontdoor.identity.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', keyVaultReaderRoleDefinitionId)
    principalType: 'ServicePrincipal'
  }
}

resource frontdoor 'Microsoft.Cdn/profiles@2023-07-01-preview' = {
  name: afdName
  location: 'Global'
  sku: {
    name: 'Premium_AzureFrontDoor'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    originResponseTimeoutSeconds: 60
  }
}

resource frontdoor_endpoint 'Microsoft.Cdn/profiles/afdEndpoints@2023-07-01-preview' = {
  parent: frontdoor
  name: 'endpoint-1'
  location: 'Global'
  properties: {
    enabledState: 'Enabled'
  }
}

resource frontdoor_origin_group 'Microsoft.Cdn/profiles/originGroups@2023-07-01-preview' = {
  parent: frontdoor
  name: 'origin-grp-1'
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
      probeIntervalInSeconds: 100
    }
    sessionAffinityState: 'Disabled'
  }
}

resource star_bellee_net_latest 'Microsoft.Cdn/profiles/secrets@2022-11-01-preview' = {
  parent: frontdoor
  name: 'star-bellee-net-latest'
  properties: {
    parameters: {
      type: 'CustomerCertificate'
      secretSource: {
        id: certificateId
      }
      useLatestVersion: true
      subjectAlternativeNames: [
        '*.bellee.net'
        '*.internal.bellee.net'
      ]
    }
  }
  dependsOn: [
    keyvault_rbac
  ]
}

resource customDomain 'Microsoft.Cdn/profiles/customdomains@2022-11-01-preview' = {
  parent: frontdoor
  name: 'star-bellee-net'
  properties: {
    hostName: originFqdn
    tlsSettings: {
      certificateType: 'CustomerCertificate'
      minimumTlsVersion: 'TLS12'
      secret: {
        id: resourceId('Microsoft.Cdn/profiles/secrets', frontdoor.name, star_bellee_net_latest.name)
      }
    }
    azureDnsZone: {
      id: resourceId(externalDomainResourceGroupName, 'Microsoft.Network/dnszones', domainName)
    }
  }
  dependsOn: [
    keyvault_rbac
  ]
}

// Diagnostics Settings
resource diagnosticSettings 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: diagnosticSettingsName
  scope: frontdoor
  properties: {
    workspaceId: wks.id
    logs: logs
    metrics: metrics
  }
}

output frontDoorName string = frontdoor.name
output originGroupName string = frontdoor_origin_group.name
output customDomainName string = customDomain.properties.hostName
output resourceGroupName string = resourceGroup().name
