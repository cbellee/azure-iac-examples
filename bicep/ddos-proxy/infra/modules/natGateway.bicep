param natGatewayName string
param publicIpAddressName string
param domainNameLabel string = 'natgwy-ddos-proxy'
param enableDdosProtection bool = false
param idleTimeoutInMinutes int = 60
param tags object

@allowed([
  'Basic'
  'Standard'
])
param ddosProtectionCoverage string = 'Basic'

resource natGatewayPublicIPAddress 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: publicIpAddressName
  location: resourceGroup().location
  sku: {
    name: 'Standard'
  }
  tags: tags
  properties: {
    publicIPAllocationMethod: 'Static'
/*     ddosSettings: enableDdosProtection ? {
      protectionCoverage: ddosProtectionCoverage
    } : {} */
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: domainNameLabel
    }
  }
}

resource natGateway 'Microsoft.Network/natGateways@2020-06-01' = {
  location: resourceGroup().location
  name: natGatewayName
  sku: {
    name: 'Standard'
  }
  tags: tags
  properties: {
    idleTimeoutInMinutes: idleTimeoutInMinutes
    publicIpAddresses: [
      {
        id: natGatewayPublicIPAddress.id
      }
    ]
  }
}

output natGatewayResourceId string = natGateway.id
