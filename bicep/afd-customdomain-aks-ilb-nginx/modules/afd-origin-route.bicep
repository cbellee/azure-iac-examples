param frontDoorName string
param originGroupName string
param location string
param privateLinkServiceId string
param domainName string
param originFqdn string

var originName = 'origin-${location}'
var routeName = 'route-${location}'

resource endpoint 'Microsoft.Cdn/profiles/afdEndpoints@2023-07-01-preview' existing = {
  name: frontDoorName
}

resource customDomain 'Microsoft.Cdn/profiles/customDomains@2023-07-01-preview' existing = {
  name: domainName
}

resource originGroup 'Microsoft.Cdn/profiles/originGroups@2023-07-01-preview' existing = {
  name: originGroupName
}

resource origin 'Microsoft.Cdn/profiles/originGroups/origins@2023-07-01-preview' = {
  name: '${frontDoorName}/${originGroup.name}/${originName}'
  properties: {
    hostName: originFqdn
    httpPort: 80
    httpsPort: 443
    originHostHeader: originFqdn
    priority: 1
    weight: 1000
    enabledState: 'Enabled'
    enforceCertificateNameCheck: true
    sharedPrivateLinkResource: {
      privateLink: {
        id: privateLinkServiceId
      }
      privateLinkLocation: location
      requestMessage: 'pls approval text'
    }
  }
}

resource route 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-07-01-preview' = {
  name: '${frontDoorName}/${endpoint.name}/${routeName}'
  properties: {
    enabledState: 'Enabled'
    patternsToMatch: [
      '/*'
    ]
    customDomains: [
      {
        id: customDomain.id
      }
    ]
    forwardingProtocol: 'HttpsOnly'
    httpsRedirect: 'Enabled'
    linkToDefaultDomain: 'Disabled'
    originGroup: {
      id: originGroup.id
    }
    originPath: '/'
    supportedProtocols: [
      'Https'
    ]
  }
  dependsOn: [
    origin
  ]
}
