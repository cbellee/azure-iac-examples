param location string
param subscriptionId string = subscription().subscriptionId
param defaultDomain array
param loadBalancerName string
param subnetId string
param prefix string

var acaResourceGroupName = 'MC_${defaultDomain[0]}-rg_${defaultDomain[0]}_${defaultDomain[1]}'
var suffix = uniqueString(resourceGroup().id)
var name = '${prefix}-pls-${suffix}'

resource loadBalancer 'Microsoft.Network/loadBalancers@2023-04-01' existing = {
  name: loadBalancerName
  scope: az.resourceGroup(acaResourceGroupName)
}

resource privateLinkService 'Microsoft.Network/privateLinkServices@2023-04-01' = {
  name: name
  location: location
  properties: {
    autoApproval: {
      subscriptions: [
        subscriptionId
      ]
    }
    visibility: {
      subscriptions: [
        subscriptionId
      ]
    }
    fqdns: []
    enableProxyProtocol: false
    loadBalancerFrontendIpConfigurations: [
      {
        id: loadBalancer.properties.frontendIPConfigurations[0].id
      }
    ]
    ipConfigurations: [
      {
        name: 'ipconfig-0'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
  }
}

output id string = privateLinkService.id
output name string = privateLinkService.name
