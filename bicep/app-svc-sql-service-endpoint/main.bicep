param location string
param containerName string
param sqlAdminPassword string
param sqlAdminUserName string
param tags object = {
  costcenter: '1234567890'
  environment: 'dev'
}

module vnetModule './modules/vnet.bicep' = {
  name: 'vnetDeploymnet'
  params: {
    location: location
    tags: tags
  }
}

module sqlModule './modules/sql.bicep' = {
  name: 'sqlDeployment'
  params: {
    location: location
    tags: tags
    sqlDBName: 'SampleDB'
    administratorLoginPassword: sqlAdminPassword
    administratorLogin: sqlAdminUserName
    subnetId: vnetModule.outputs.subnetIds[0].id
  }
}

module appServiceModule './modules/appsvc.bicep' = {
  name: 'appServiceDeployment'
  params: {
    location: location
    tags: tags
    subnetId: vnetModule.outputs.subnetIds[0].id
    containerName: containerName
  }
}
