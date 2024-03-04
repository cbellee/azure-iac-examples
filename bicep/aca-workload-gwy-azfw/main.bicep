param location string
param containerAppName string
param imageName string
param domain string
param keyVaultName string
param publicDnsZoneResourceGroup string
param dnsHostName string

@secure()
param tlsCertSecretId string

param containers array = [
  {
    name: containerAppName
    image: imageName
    command: []
    resources: {
      cpu: '8'
      memory: '16Gi'
    }
  }
]

param workloadProfiles array = [ {
    workloadProfileType: 'Consumption'
    name: 'consumption'
  }
  {
    workloadProfileType: 'D16'
    name: 'gp-D16'
    minimumCount: 1
    maximumCount: 3
  }
  {
    workloadProfileType: 'E16'
    name: 'mo-E16'
    minimumCount: 0
    maximumCount: 3
  }
]

var suffix = uniqueString(resourceGroup().id)
var virtualNetworkName = 'vnet-${suffix}'
var workspaceName = 'workspace-${suffix}'
var firewallName = 'fw-${suffix}'
var firewallPublicIpName = 'fw-pip-${suffix}'
var udrName = 'udr-${suffix}'
var appGatewayName = 'ag-${suffix}'
var appGatewayPipName = 'ag-pip-${suffix}'
var appGatewayUmidName = 'ag-umid-${suffix}'
var backendFqdn = '${container_app.name}.${aca_environment.outputs.defaultDomain}'

resource umid_app_gateway 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: appGatewayUmidName
  location: location
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

// grant application gateway user managed identity keyvault access policy
module app_gateway_key_vault_policies 'modules/keyVaultAccessPolicy.bicep' = {
  name: 'module-keyvault-access-policy'
  params: {
    accessPolicies: [
      {
        permissions: {
          keys: [
            'get'
            'list'
          ]
          secrets: [
            'get'
            'list'
          ]
          certificates: [
            'get'
            'list'
          ]
        }
        tenantId: tenant().tenantId
        objectId: umid_app_gateway.properties.principalId
      }
    ]
    keyVaultName: keyVault.name
  }
}

resource la_workspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: 'Standard'
    }
  }
}

resource aca_udr 'Microsoft.Network/routeTables@2022-07-01' = {
  name: udrName
  location: location
  properties: {
    routes: [
      {
        name: 'internal'
        properties: {
          nextHopType: 'VirtualAppliance'
          addressPrefix: '0.0.0.0/0'
          nextHopIpAddress: '192.168.9.4'
        }
      }
    ]
  }
}

resource virtual_network 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '192.168.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'infra-subnet'
        properties: {
          addressPrefix: '192.168.0.0/21'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          routeTable: {
            id: aca_udr.id
          }
          delegations: [
            {
              name: 'Microsoft.App.testClients'
              properties: {
                serviceName: 'Microsoft.App/environments'
                actions: [
                  'Microsoft.Network/virtualNetworks/subnets/join/action'
                ]
              }
            }
          ]
        }
      }
      {
        name: 'ApplicationGatewaySubnet'
        properties: {
          addressPrefix: '192.168.8.0/24'
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '192.168.9.0/24'
        }
      }
    ]
  }
}

module aca_environment './modules/acaEnvironment.bicep' = {
  name: 'aca-environment-deployment'
  params: {
    location: location
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'infra-subnet')
    workspaceName: la_workspace.name
    workloadProfiles: workloadProfiles
  }
  dependsOn: [
    virtual_network
    azure_firewall
  ]
}

resource container_app 'Microsoft.App/containerapps@2022-11-01-preview' = {
  name: containerAppName
  kind: 'containerapps'
  location: location
  properties: {
    configuration: {
      secrets: []
      registries: []
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 80
      }
    }
    template: {
      containers: containers
      scale: {
        minReplicas: 1
        maxReplicas: 8
      }
    }
    managedEnvironmentId: aca_environment.outputs.id
    workloadProfileName: 'gp-D16'
  }
}

module private_dns_zone 'modules/privateDnsZone.bicep' = {
  name: 'private-dns-deployment'
  params: {
    virtualNetworkId: virtual_network.id
    zoneName: aca_environment.outputs.defaultDomain
  }
}

module private_dns_record_wildcard 'modules/dnsRecord.bicep' = {
  name: 'private-dns-record-wildcard-deployment'
  params: {
    zoneName: aca_environment.outputs.defaultDomain
    recordName: '*'
    ipAddress: aca_environment.outputs.ipAddress
  }
  dependsOn: [
    private_dns_zone
  ]
}

module private_dns_record_root 'modules/dnsRecord.bicep' = {
  name: 'private-dns-record-root-deployment'
  params: {
    zoneName: aca_environment.outputs.defaultDomain
    recordName: '@'
    ipAddress: aca_environment.outputs.ipAddress
  }
  dependsOn: [
    private_dns_zone
  ]
}

module azure_firewall 'modules/azureFirewall.bicep' = {
  name: 'azure-firewall-deployment'
  params: {
    publicIpName: firewallPublicIpName
    location: location
    name: firewallName
    workspaceName: la_workspace.name
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', virtual_network.name, 'AzureFirewallSubnet')
  }
}

module app_gateway 'modules/applicationGateway.bicep' = {
  name: 'app-gateway-deployment'
  params: {
    backendIpAddressOrFqdn: backendFqdn
    appGatewayIpName: appGatewayPipName
    frontendHostName: '${dnsHostName}.${domain}'
    location: location
    name: appGatewayName
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', virtual_network.name, 'ApplicationGatewaySubnet')
    tlsCertSecretId: tlsCertSecretId
    umidResourceId: umid_app_gateway.id
    workspaceId: la_workspace.id
  }
}

module app_gateway_public_dns_record 'modules/publicDnsRecord.bicep' = {
  scope: resourceGroup(publicDnsZoneResourceGroup)
  name: 'appgwy-public-dns-record-deployment'
  params: {
    zoneName: domain
    ipAddress: app_gateway.outputs.appGwyPublicIpAddress
    recordName: dnsHostName
  }
}
