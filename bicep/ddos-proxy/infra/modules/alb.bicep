param loadBalancerName string
param publicIpAddressName string
param domainNameLabel string = 'alb-ddos-proxy'
// param enableDdosProtection bool = false
param idleTimeoutInMinutes int = 4
param enableTcpReset bool = true
param backendPoolName string
param tags object

/* @allowed([
  'Basic'
  'Standard'
])
param ddosProtectionCoverage string = 'Basic'
 */

resource lbPublicIP 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
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
        name: 'IpConfiguration'
        properties: {
          publicIPAddress: {
            id: lbPublicIP.id
          }
        }
      }
    ]
    loadBalancingRules: [
      {
        name: 'smb-lb-rule'
        properties: {
          backendAddressPool: {
            id: '${resourceId('Microsoft.Network/loadbalancers', loadBalancerName)}/backendAddressPools/${backendPoolName}'
          }
          frontendPort: 445
          backendPort: 445
          frontendIPConfiguration: {
            id: '${resourceId('Microsoft.Network/loadbalancers', loadBalancerName)}/frontendIPConfigurations/IpConfiguration'
          }
          loadDistribution: 'SourceIPProtocol'
          idleTimeoutInMinutes: idleTimeoutInMinutes
          enableTcpReset: enableTcpReset
          probe: {
            id: '${resourceId('Microsoft.Network/loadbalancers', loadBalancerName)}/probes/smb-lb-rule-probe'
          }
          protocol: 'Tcp'
        }
      }
      {
        name: 'dns-lb-rule'
        properties: {
          backendAddressPool: {
            id: '${resourceId('Microsoft.Network/loadbalancers', loadBalancerName)}/backendAddressPools/${backendPoolName}'
          }
          frontendPort: 53
          backendPort: 53
          frontendIPConfiguration: {
            id: '${resourceId('Microsoft.Network/loadbalancers', loadBalancerName)}/frontendIPConfigurations/IpConfiguration'
          }
          loadDistribution: 'SourceIPProtocol'
          idleTimeoutInMinutes: idleTimeoutInMinutes
          enableTcpReset: enableTcpReset
          probe: {
            id: '${resourceId('Microsoft.Network/loadbalancers', loadBalancerName)}/probes/dns-lb-rule-probe'
          }
          protocol: 'Udp'
        }
      }
      {
        name: 'smtp-lb-rule'
        properties: {
          backendAddressPool: {
            id: '${resourceId('Microsoft.Network/loadbalancers', loadBalancerName)}/backendAddressPools/${backendPoolName}'
          }
          frontendPort: 25
          backendPort: 25
          frontendIPConfiguration: {
            id: '${resourceId('Microsoft.Network/loadbalancers', loadBalancerName)}/frontendIPConfigurations/IpConfiguration'
          }
          loadDistribution: 'SourceIPProtocol'
          idleTimeoutInMinutes: idleTimeoutInMinutes
          enableTcpReset: enableTcpReset
          probe: {
            id: '${resourceId('Microsoft.Network/loadbalancers', loadBalancerName)}/probes/smtp-lb-rule-probe'
          }
          protocol: 'Tcp'
        }
      }
      {
        name: 'ftp-lb-rule'
        properties: {
          backendAddressPool: {
            id: '${resourceId('Microsoft.Network/loadbalancers', loadBalancerName)}/backendAddressPools/${backendPoolName}'
          }
          frontendPort: 21
          backendPort: 21
          frontendIPConfiguration: {
            id: '${resourceId('Microsoft.Network/loadbalancers', loadBalancerName)}/frontendIPConfigurations/IpConfiguration'
          }
          loadDistribution: 'SourceIPProtocol'
          idleTimeoutInMinutes: idleTimeoutInMinutes
          enableTcpReset: enableTcpReset
          probe: {
            id: '${resourceId('Microsoft.Network/loadbalancers', loadBalancerName)}/probes/ftp-lb-rule-probe'
          }
          protocol: 'Tcp'
        }
      }
    ]
    backendAddressPools: [
      {
        name: backendPoolName
      }
    ]
    probes: [
      {
        name: 'smb-lb-rule-probe'
        properties: {
          intervalInSeconds: 15
          port: 445
          numberOfProbes: 2
          protocol: 'Tcp'
        }
      }
      {
        name: 'dns-lb-rule-probe'
        properties: {
          intervalInSeconds: 15
          port: 53
          numberOfProbes: 2
          protocol: 'Tcp'
        }
      }
      {
        name: 'smtp-lb-rule-probe'
        properties: {
          intervalInSeconds: 15
          port: 21
          numberOfProbes: 2
          protocol: 'Tcp'
        }
      }
      {
        name: 'ftp-lb-rule-probe'
        properties: {
          intervalInSeconds: 15
          port: 21
          numberOfProbes: 2
          protocol: 'Tcp'
        }
      }
    ]
  }
}

output albBackendPoolResourceId string = loadBalancer.properties.backendAddressPools[0].id
