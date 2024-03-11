param location string
param nodeSubnetId string
param vmSize string = 'Standard_D2_v3'
param kubernetesVersion string = '1.28.3'
param sshPublicKey string
param linuxUsername string = 'aksuser'
param adminGropuObjectId string
param istioVersion string = 'asm-1-20'

var suffix = uniqueString(resourceGroup().id)
var clusterName = 'aks-${suffix}'

resource aks 'Microsoft.ContainerService/managedClusters@2023-11-01' = {
  name: clusterName
  location: location
  sku: {
    name: 'Base'
    tier: 'Free'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serviceMeshProfile: {
      mode: 'Istio'
      istio: {
        components: {
          egressGateways: null
          ingressGateways: null
        }
        certificateAuthority: null
        revisions: [
          istioVersion
        ]
      }
    }
    networkProfile: {
      networkPluginMode: 'overlay'
      podCidr: '192.168.0.0/16'
      networkPlugin: 'azure'
    }
    dnsPrefix: clusterName
    agentPoolProfiles: [
      {
        name: 'system'
        mode: 'System'
        maxPods: 50
        vnetSubnetID: nodeSubnetId
        vmSize: vmSize
        type: 'VirtualMachineScaleSets'
        osType: 'Linux'
        osSKU: 'CBLMariner'
        count: 1
      }
      {
        name: 'user'
        mode: 'User'
        maxPods: 50
        vnetSubnetID: nodeSubnetId
        vmSize: vmSize
        type: 'VirtualMachineScaleSets'
        osType: 'Linux'
        osSKU: 'CBLMariner'
        count: 1
      }
    ]
    kubernetesVersion: kubernetesVersion
    azureMonitorProfile: {
      metrics: {
        enabled: true
      }
    }
    linuxProfile: {
      adminUsername: linuxUsername
      ssh: {
        publicKeys: [
          {
            keyData: sshPublicKey
          }
        ]
      }
    }
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
    oidcIssuerProfile: {
      enabled: true
    }
    aadProfile: {
      adminGroupObjectIDs: [
        adminGropuObjectId
      ]
      enableAzureRBAC: true
      tenantID: tenant().tenantId
      managed: true
    }
  }
}



output name string = aks.name
output fqdn string = aks.properties.fqdn
output nodeResourceGroup string = aks.properties.nodeResourceGroup
