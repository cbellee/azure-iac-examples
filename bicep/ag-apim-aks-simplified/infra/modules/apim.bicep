param apimSku object = {
  name: 'Developer'
  capacity: 1
}
param gatewayHostName string = 'proxy'

@secure()
param keyVaultCertificateSecretId string
param subnetId string
param location string
param deployCertificates bool = false
param tags object
param privateDnsZoneName string
param hubVnetId string
param spokeVnetId string
param workspaceId string
param retentionInDays int = 30
param zones array

var suffix = uniqueString(resourceGroup().id)
var apimName = 'api-mgmt-${suffix}'
var hostNameConfigurations = [
  {
    type: 'Proxy'
    hostName: gatewayHostName
    certificateSource: 'KeyVault'
    keyVaultId: keyVaultCertificateSecretId
    defaultSslBinding: true
  }
]

resource apim 'Microsoft.ApiManagement/service@2021-12-01-preview' = {
  name: apimName
  location: location
  sku: apimSku
  zones: zones
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: 'cbellee@microsoft.com'
    publisherName: 'KainiIndustries'
    notificationSenderEmail: 'apim-noreply@mail.windowsazure.com'
    hostnameConfigurations: (deployCertificates ? hostNameConfigurations : json('null'))
    virtualNetworkConfiguration: {
      subnetResourceId: subnetId
    }
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Ssl30': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TripleDes168': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Ssl30': 'False'
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Protocols.Server.Http2': 'False'
    }
    virtualNetworkType: 'Internal'
  }
  dependsOn: []
}

resource apimPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing = {
  name: privateDnsZoneName
}

resource apimProxyDnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  parent: apimPrivateDnsZone
  name: 'gateway'
  properties: {
    aRecords: [
      {
        ipv4Address: apim.properties.privateIPAddresses[0]
      }
    ]
    ttl: 3600
  }
}

resource ApimHubVirtualNetworkDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${apimPrivateDnsZone.name}/${apimPrivateDnsZone.name}-hub-link'
  tags: tags
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: hubVnetId
    }
  }
}

resource ApimSpokeVirtualNetworkDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${apimPrivateDnsZone.name}/${apimPrivateDnsZone.name}-spoke-link'
  tags: tags
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: spokeVnetId
    }
  }
}

resource apimDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'apim-diagnostics'
  scope: apim
  properties: {
    logs: [
      {
        category: 'GatewayLogs'
        enabled: true
        retentionPolicy: {
          days: retentionInDays
          enabled: true
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          days: retentionInDays
          enabled: true
        }
      }
    ]
    workspaceId: workspaceId
  }
}

output apimPrivateIpAddress string = apim.properties.privateIPAddresses[0]
output apimDnsName array = split(replace(apim.properties.gatewayUrl, 'https://', ''), '.')
output apimName string = apim.name
output apimManagedIdentityPrincipalId string = apim.identity.principalId
