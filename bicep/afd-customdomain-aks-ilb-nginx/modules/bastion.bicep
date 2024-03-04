param location string
param subnetId string
param prefix string

var affix = uniqueString(resourceGroup().id)
var bastionName = '${prefix}-bas-${affix}'
var bastionPipName = '${prefix}-bast-pip-${affix}'

resource bastion_pip 'Microsoft.Network/publicIPAddresses@2023-06-01' = {
  name: bastionPipName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    idleTimeoutInMinutes: 4
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-06-01' = {
  name: bastionName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    enableFileCopy: true
    enableTunneling: true
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          publicIPAddress: {
            id: bastion_pip.id
          }
        }
      }
    ]
  }
}

output name string = bastion.name
output id string = bastion.id
