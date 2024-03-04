param name string
param sku string
param capacity int
param subnetId string
param publisherEmail string
param publisherName string
param customProperties object

resource apim 'Microsoft.ApiManagement/service@2020-12-01' = {
  name: name
  location: resourceGroup().location
  sku: {
    name: sku
    capacity: capacity
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    customProperties: customProperties
    virtualNetworkType: 'External'
    virtualNetworkConfiguration: {
      subnetResourceId: subnetId
    }
  }
}
