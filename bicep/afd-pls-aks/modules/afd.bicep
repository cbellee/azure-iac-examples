param location string
param prefix string

var affix = uniqueString(resourceGroup().id)
var afdName = '${prefix}-afd-${affix}'

resource frontdoor 'Microsoft.Cdn/profiles@2023-07-01-preview' = {
  name: afdName
  location: 'Global'
  sku: {
    name: 'Premium_AzureFrontDoor'
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
