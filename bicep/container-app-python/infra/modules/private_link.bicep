@description('naming suffix based on resource group name hash')
param suffix string

@description('location to deploy private link endpoint web app')
param location string

@description('private link resource type')
param resourceType string

@description('private link resource name')
param resourceName string

@description('private link resource group id')
param groupId string

@description('resource id of private link subnet')
param subnet string

var privateEndpointName = '${groupId}-pep-${suffix}'
var privateEndpointConnectionName = '${groupId}-pep-cxn-${suffix}'

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: privateEndpointName
  location: location
  properties: {
    privateLinkServiceConnections: [
      {
        name: privateEndpointConnectionName
        properties: {
          privateLinkServiceId: resourceId(resourceType, resourceName)
          groupIds: [
            groupId
          ]
        }
      }
    ]
    subnet: {
      id: subnet
    }
  }
}

output privateEndpointName string = privateEndpoint.name
output privateEndpoint object = privateEndpoint
