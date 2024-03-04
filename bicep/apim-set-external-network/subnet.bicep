param vnetName string
param subnetName string
param nsgId string
param subnetAddressPrefix string

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
  name: '${vnetName}/${subnetName}'
  properties: {
    addressPrefix: subnetAddressPrefix
    networkSecurityGroup: {
      id: nsgId
    }
  }
}

output subnetId string = subnet.id
