param location string
param prefix string
param isMTLSEnabled bool = false

targetScope = 'subscription'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: '${prefix}-${location}-rg'
  location: location
}

module acr 'modules/acr.bicep' = {
  name: 'module-acr-${location}'
  scope: resourceGroup
  params: {
    location: location
    prefix: prefix
  }
}

module wks './modules/wks.bicep' = {
  name: 'module-law-${location}'
  scope: resourceGroup
  params: {
    location: location
    prefix: prefix
  }
}

module appEnv 'modules/appEnvironment.bicep' = {
  name: 'module-containerenv-${location}'
  scope: resourceGroup
  params: {
    location: location
    workspaceName: wks.outputs.name
    isMTLSEnabled: isMTLSEnabled
    isZoneRedundant: !empty(pickZones('Microsoft.App', 'managedEnvironments', location)) ? true : false
    prefix: prefix
  }
}

module acrPullUmid 'modules/umid.bicep' = {
  scope: resourceGroup
  name: 'module-acrPull-umid'
  params: {
    acrName: acr.outputs.name
    location: location
  }
}

output resourceGroupName string = resourceGroup.name
output acaEnvironmentName string = appEnv.outputs.name
output location string = location
output acrName string = acr.outputs.name
output umidName string = acrPullUmid.outputs.name
output umidId string = acrPullUmid.outputs.id
