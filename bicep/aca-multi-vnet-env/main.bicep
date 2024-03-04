param location string = 'australiaeast'
param prefix string = 'cbellee'
param imageName string = 'mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
param sshKey string
param addressPrefixes array = [ '10.0.0.0/16' ]
param subnets array = [
  {
    name: 'aca-subnet-1'
    properties: {
      addressPrefix: '10.0.0.0/23'
    }
  }
  {
    name: 'aca-subnet-2'
    properties: {
      addressPrefix: '10.0.4.0/23'
    }
  }
]

var suffix = uniqueString(resourceGroup().id)
var vnetName = '${prefix}-${suffix}-vnet'
var vmVnetName = '${prefix}-${suffix}-vm-vnet'
var workspaceName = '${prefix}-${suffix}-wks'
var bastionName = '${prefix}-${suffix}-bas'
var bastionPipName = '${prefix}-${suffix}-bas-pip'
var acrName = '${prefix}${suffix}acr'
var appName = '${prefix}-${suffix}-app'
var appEnvironmentName = '${prefix}-${suffix}'

targetScope = 'resourceGroup'

module aca_vnet 'modules/vnet.bicep' = {
  name: 'aca-vnet-module'
  params: {
    location: location
    name: vnetName
    addressPrefixes: addressPrefixes
    subnets: subnets
  }
}

module vm_vnet 'modules/vnet.bicep' = {
  name: 'vm-vnet-module'
  params: {
    location: location
    name: vmVnetName
    addressPrefixes: [ '10.1.0.0/16' ]
    subnets: [
      {
        name: 'vm-subnet'
        properties: {
          addressPrefix: '10.1.0.0/24'
        }
      }
      {
        name: 'plink-subnet'
        properties: {
          addressPrefix: '10.1.1.0/24'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '10.1.2.0/24'
        }
      }
    ]
  }
}

module workspace 'modules/wks.bicep' = {
  name: 'wks-module'
  params: {
    location: location
    workspaceName: workspaceName
  }
}

module bastion 'modules/bastion.bicep' = {
  name: 'bastion-module'
  params: {
    bastionName: bastionName
    bastionPipName: bastionPipName
    location: location
    subnetId: vm_vnet.outputs.subnets[2].id
  }
}

module appEnvironment 'modules/appEnvironment.bicep' = [
for (subnet, index) in subnets: {
  name: 'app-environment-module-${index}'
  params: {
    location: location
    appEnvironmentName: '${appEnvironmentName}-${index}-env'
    workspaceName: workspace.outputs.name
    subnetId: resourceId('Microsoft.Network/virtualNetworks/subnets', aca_vnet.outputs.name, subnet.name)
    isInternal: true
    isZoneRedundant: false
  }
  dependsOn: [
    aca_vnet
    workspace
  ]
}
]

module containerApp 'modules/containerApp.bicep' = [
  for (subnet, index) in subnets: {
    name: 'container-app-module-${index}'
    dependsOn: [
      workspace
      appEnvironment
    ]
    params: {
      location: location
      appName: '${appName}-${index}'
      environmentId: resourceId('Microsoft.App/managedEnvironments', '${appEnvironmentName}-${index}-env')
      imageName: imageName
    }
  }
]

module acr 'modules/acr.bicep' = {
  name: 'acr-module'
  params: {
    location: location
    name: acrName
  }
}

resource vm_nic 'Microsoft.Network/networkInterfaces@2023-05-01' = {
  name: 'linux-vm-nic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vm_vnet.outputs.name, vm_vnet.outputs.subnets[0].name)
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2023-07-01' = {
  name: 'linux-vm'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1s'
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vm_nic.id
        }
      ]
    }
    osProfile: {
      computerName: 'linux-vm'
      adminUsername: 'localadmin'
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/localadmin/.ssh/authorized_keys'
              keyData: sshKey
            }
          ]
        }
      }
    }
  }
}

resource aca_private_dns_zone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: '${location}.azurecontainerapps.io'
  location: 'global'
  properties: {}
}

resource acr_private_dns_zone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurecr.io'
  location: 'global'
  properties: {}
}

module env_1_a_record './modules/aRecord.bicep' = {
  name: 'env-1-a-record-module'
  params: {
    ipAddress: appEnvironment[0].outputs.ipAddress
    name: appEnvironment[0].outputs.firstDomainSegment
    zoneName: '${location}.azurecontainerapps.io'
  }
}

module env_2_a_record './modules/aRecord.bicep' = {
  name: 'env-2-a-record-module'
  params: {
    ipAddress: appEnvironment[1].outputs.ipAddress
    name: appEnvironment[1].outputs.firstDomainSegment
    zoneName: '${location}.azurecontainerapps.io'
  }
}

resource aca_vnet_dns_zone_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'aca-vnet-dns-zone-link'
  parent: aca_private_dns_zone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: aca_vnet.outputs.id
    }
  }
}

resource vm_vnet_dns_zone_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'vm-vnet-dns-zone-link'
  parent: aca_private_dns_zone
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vm_vnet.outputs.id
    }
  }
}

resource acr_vnet_dns_zone_link 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: 'acr-vnet-dns-zone-link'
  parent: acr_private_dns_zone
  location: 'global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: vm_vnet.outputs.id
    }
  }
}

module vnet_peering 'modules/vnetPeer.bicep' = {
  name: 'vnet-peer-module'
  params: {
    localVnetName: vm_vnet.outputs.name
    remoteVnetName: aca_vnet.outputs.name
  }
}

module acr_plink 'modules/plink.bicep' = {
  name: 'acr-plink-module'
  params: {
    acrName: acr.outputs.name
    location: location
    name: 'acrPrivateLinkEndpoint'
    groupId: 'registry'
    subnetId: vm_vnet.outputs.subnets[1].id
  }
}

output vmId string = vm.id
output bastionName string = bastion.outputs.name
output app1Fqdn string = containerApp[0].outputs.fqdn
output app2Fqdn string = containerApp[1].outputs.fqdn
