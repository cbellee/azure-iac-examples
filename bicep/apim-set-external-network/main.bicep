param vnetName string
param subnetName string
param publicIpName string
param apimName string
param updateApim bool = false
param nsgName string
param domainLabelPrefix string

resource publicIp 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  location: resourceGroup().location
  name: publicIpName
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: domainLabelPrefix
    }
  }
}

module apimNsgModule 'nsg.bicep' = {
  name: 'apimNsgDeployment'
  params: {
    location: resourceGroup().location
    nsgName: nsgName
  }
}

module subnetModule 'subnet.bicep' = {
  name: 'subnetNsgUpdateDeployment'
  params: {
    subnetName: subnetName
    subnetAddressPrefix: reference(resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName), '2021-02-01').addressPrefix
    vnetName: vnetName
    nsgId: apimNsgModule.outputs.nsgId
  }
}

module apim 'apim.bicep' = if (updateApim == true) {
  name: 'apimUpdate'
  params: {
    name: apimName
    sku: reference(resourceId('Microsoft.ApiManagement/service', apimName), '2020-12-01', 'Full').sku.name
    capacity: reference(resourceId('Microsoft.ApiManagement/service', apimName), '2020-12-01', 'Full').sku.capacity
    publisherEmail: reference(resourceId('Microsoft.ApiManagement/service', apimName), '2020-12-01', 'Full').properties.publisherEmail
    publisherName: reference(resourceId('Microsoft.ApiManagement/service', apimName), '2020-12-01', 'Full').properties.publisherName
    customProperties: reference(resourceId('Microsoft.ApiManagement/service', apimName), '2020-12-01', 'Full').properties.customProperties
    subnetId: subnetModule.outputs.subnetId
  }
}
