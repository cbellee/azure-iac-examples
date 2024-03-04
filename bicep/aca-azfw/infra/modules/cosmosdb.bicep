param location string = resourceGroup().location
param name string
param dbName string = 'checkins'
param tags object
param partitionKey string = 'user_id'

resource cs 'Microsoft.DocumentDB/databaseAccounts@2021-06-15' = {
  location: location
  kind: 'GlobalDocumentDB'
  name: name
  tags: tags
  properties: {
    locations: [
      {
        locationName: location
        isZoneRedundant: false
      }
    ]
    databaseAccountOfferType: 'Standard'
    createMode: 'Default'
    publicNetworkAccess: 'Enabled'
  }
}

resource db 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2021-06-15' = {
  name: dbName
  parent: cs
  tags: tags
  location: location
  properties: {
    resource: {
      id: dbName
    }
    options: {
      autoscaleSettings: {
        maxThroughput: 4000
      }
    }
  }
}

resource container 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2021-06-15' = {
  name: 'default'
  location: location
  parent: db
  properties: {
    options: {
      autoscaleSettings: {
        maxThroughput: 4000
      }
    }
    resource: {
      id: 'default'
      partitionKey: {
        kind: 'Hash'
        paths: [
          '/${partitionKey}'
        ]
      }
    }
  }
}

output name string = cs.name
output id string = cs.id
output dbName string = db.name
output collectionName string = container.name
output connectionString string = listConnectionStrings(resourceId('Microsoft.DocumentDB/databaseAccounts', name), '2021-06-15').connectionStrings[1].connectionString
output endpointUri string = cs.properties.documentEndpoint
output masterKey string = cs.listKeys().primaryMasterKey
