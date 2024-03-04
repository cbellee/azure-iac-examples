param loadBalancerName string
param vmssSubnetResourceId string
param backendAddressPoolName string
param tags object

resource loadBalancer 'Microsoft.Network/loadBalancers@2020-06-01' = {
  location: resourceGroup().location
  name: loadBalancerName
  sku: {
    name: 'Standard'
  }
  tags: tags
  properties: {
    frontendIPConfigurations: [
      {
        name: 'ilbIpConfiguration'
        zones: [
          '1'
          '2'
          '3'
        ]
        properties: {
          subnet: {
            id: vmssSubnetResourceId
          }
        }
      }
    ]
    loadBalancingRules: [
      {
        properties: {
          frontendPort: 80
          backendPort: 80
          idleTimeoutInMinutes: 15
          protocol: 'Tcp'
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadbalancers', loadBalancerName, 'frontendIPConfigurations', 'ilbIpConfiguration')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadbalancers', loadBalancerName, 'backendAddressPools', backendAddressPoolName)
          }
          probe: {
            id: resourceId('Microsoft.Network/loadbalancers', loadBalancerName, 'probes', 'http-lb-rule-probe')
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: backendAddressPoolName
      }
    ]
    probes: [
      {
        name: 'http-lb-rule-probe'
        properties: {
          intervalInSeconds: 15
          port: 80
          numberOfProbes: 2
          protocol: 'Tcp'
        }
      }
    ]
  }
}

output ilbBackendPoolResourceId string = loadBalancer.properties.backendAddressPools[0].id
