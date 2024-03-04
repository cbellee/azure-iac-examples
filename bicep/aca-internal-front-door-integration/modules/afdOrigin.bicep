param location string
param containerAppFqdn string
param privateLinkServiceId string
param frontDoorName string
param routingWeight int = 50

var suffix = uniqueString(resourceGroup().id)
var originGroupName = 'originGroup-01'
var originName = 'origin-${location}-${suffix}'

resource frontDoor 'Microsoft.Cdn/profiles@2023-07-01-preview' existing = {
  name: frontDoorName
}

resource originGroup 'Microsoft.Cdn/profiles/originGroups@2023-07-01-preview' = {
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

resource afdOrigin 'Microsoft.Cdn/profiles/originGroups/origins@2023-07-01-preview' = {
  parent: originGroup
  name: originName
  properties: {
    hostName: containerAppFqdn
    httpPort: 80
    httpsPort: 443
    originHostHeader: containerAppFqdn
    priority: 1
    weight: routingWeight
    enabledState: 'Enabled'
    sharedPrivateLinkResource: {
      privateLink: {
        id: privateLinkServiceId
      }
      privateLinkLocation: location
      status: 'Approved'
      requestMessage: 'Please approve this request to allow Front Door to access the container app'
    }
    enforceCertificateNameCheck: true
  }
}

output originGroupName string = originGroup.name
output frontDoorName string = frontDoor.name
