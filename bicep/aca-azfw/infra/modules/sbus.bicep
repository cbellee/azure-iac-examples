param name string
param skuName string = 'Standard'
param location string
param tags object
param sbQueueName string = 'checkin'

var sasKeyName = 'saskey${name}'

resource sb 'Microsoft.ServiceBus/namespaces@2021-06-01-preview' = {
  name: name
  tags: tags
  location: location
  sku: {
    name: skuName
  }
}

resource queue 'Microsoft.ServiceBus/namespaces/queues@2021-06-01-preview' = {
  parent: sb
  name: sbQueueName
  properties: {
    maxDeliveryCount: 10
    deadLetteringOnMessageExpiration: true
    requiresDuplicateDetection: true
  }
}

resource sbSasKey 'Microsoft.ServiceBus/namespaces/AuthorizationRules@2021-06-01-preview' = {
  name: sasKeyName
  parent: sb
  properties: {
    rights: [
      'Listen'
      'Manage'
      'Send'
    ]
  }
}

output id string = sb.id
output endpoint string = sb.properties.serviceBusEndpoint
output connectionString string = listkeys(resourceId('Microsoft.ServiceBus/namespaces/authorizationRules', sb.name, sasKeyName), '2021-06-01-preview').primaryConnectionString
output queueName string = sbQueueName
