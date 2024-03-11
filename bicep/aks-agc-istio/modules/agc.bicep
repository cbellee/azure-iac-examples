param location string
param subnetId string

var suffix = uniqueString(resourceGroup().id)
var ag4cName = 'ag4c-${suffix}'
var frontendName = 'ag4c-frontend-${suffix}'
var associationName = 'ag4c-association-${suffix}'

resource agc 'Microsoft.ServiceNetworking/trafficControllers@2023-11-01' = {
  name: ag4cName
  location: location
}

resource agcFrontend 'Microsoft.ServiceNetworking/trafficControllers/frontends@2023-11-01' = {
  parent: agc
  name: frontendName
  location: location
}
resource agcAssociation 'Microsoft.ServiceNetworking/trafficControllers/associations@2023-11-01' = {
  parent: agc
  name: associationName
  location: location
  properties: {
    associationType: 'subnets'
    subnet: {
      id: subnetId
    }
  }
}

output name string = agc.name
output id string = agc.id
output frontendName string = agcFrontend.name
