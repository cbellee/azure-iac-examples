param frontDoorName string
param endpointName string
param originGroupName string
param customDomainResourceName string

var routeName = 'default-route'

resource profile 'Microsoft.Cdn/profiles@2023-07-01-preview' existing = {
  name: frontDoorName
}

resource originGroup 'Microsoft.Cdn/profiles/originGroups@2023-07-01-preview' existing = {
  name: originGroupName
}

resource customDomain 'Microsoft.Cdn/profiles/customDomains@2023-07-01-preview' existing = {
  name: customDomainResourceName
}

resource endpoint 'Microsoft.Cdn/profiles/afdEndpoints@2023-07-01-preview' existing = {
  name: endpointName
  parent: profile
}

resource route 'Microsoft.Cdn/profiles/afdEndpoints/routes@2023-07-01-preview' = {
  name: '${profile.name}/${endpoint.name}/${routeName}' // BUG: using 'parent' property fails as the resource name includes the parent's endpoint and profile  
  properties: {
    enabledState: 'Enabled'
    patternsToMatch: [
      '/*'
    ]
     customDomains: [
      {
        id: resourceId('Microsoft.Cdn/profiles/customDomains', profile.name, customDomainResourceName)
      }
    ]
    forwardingProtocol: 'HttpsOnly'
    httpsRedirect: 'Enabled'
    linkToDefaultDomain: 'Disabled'
    originGroup: {
      id: resourceId('Microsoft.Cdn/profiles/originGroups', profile.name, originGroup.name)
    }
    originPath: '/'
    supportedProtocols: [
      'Https'
    ]
  }
  dependsOn: [
    originGroup
    customDomain
  ]
}
