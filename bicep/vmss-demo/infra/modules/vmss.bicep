param vmSku string = 'Standard_B2ms'
param vmssSubnetId string
param appGatewayResourceId string
param workspaceId string
param workspaceKey string
param appGatewayBePoolResourceId string
param sshPublicKey string
param vmssExtensionCustomScriptUri string
param forceScriptUpdate int
param storageAccountName string

@description('The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version.')
@allowed([
  '12.04.5-LTS'
  '14.04.5-LTS'
  '16.04.0-LTS'
  '18.04-LTS'
])
param ubuntuOSVersion string = '18.04-LTS'

@minValue(1)
@maxValue(100)
param instanceCount int
param adminUsername string

@secure()
param adminPassword string
param location string = resourceGroup().location

var prefix = toLower(uniqueString(resourceGroup().id))
var vmssName = 'vmss-${prefix}'
var longprefix = toLower(vmssName)
var publicIPAddressName = '${prefix}-pip'
var autoScaleName = '${prefix}-apgwy-autoscale'
var nicname = '${prefix}-nic'
var ipConfigName = '${prefix}ipconfig'
var imageReference = osType
var osType = {
  publisher: 'Canonical'
  offer: 'UbuntuServer'
  sku: ubuntuOSVersion
  version: 'latest'
}

var dataContributorRoleId = resourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')

resource publicIP 'Microsoft.Network/publicIPAddresses@2022-01-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: longprefix
    }
  }
}

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2022-03-01' = {
  name: vmssName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: vmSku
    tier: 'Standard'
    capacity: instanceCount
  }
  properties: {
    overprovision: false
    upgradePolicy: {
      automaticOSUpgradePolicy: {
        enableAutomaticOSUpgrade: true
      }
      mode: 'Automatic'
      rollingUpgradePolicy: {
        maxBatchInstancePercent: 10
      }
    }
    doNotRunExtensionsOnOverprovisionedVMs: false
    scaleInPolicy: {
      rules: [
        'OldestVM'
      ]
    }
    virtualMachineProfile: {
      scheduledEventsProfile: {
        terminateNotificationProfile: {
          enable: true
          notBeforeTimeout: 'PT15M'
        }
      }
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
        }
        imageReference: imageReference
      }
      extensionProfile: {
        extensions: [
          {
            name: 'app-config'
            properties: {
              publisher: 'Microsoft.Azure.Extensions'
              forceUpdateTag: string(forceScriptUpdate)
              type: 'CustomScript'
              typeHandlerVersion: '2.1'
              autoUpgradeMinorVersion: true
              settings: {
                timestamp: int(forceScriptUpdate)
              }
              protectedSettings: {
                managedIdentity: {}
                fileUris: [
                  '${vmssExtensionCustomScriptUri}/install.sh'
                  '${vmssExtensionCustomScriptUri}/vmss-test-app'
                ]
                commandToExecute: 'sh ./install.sh'
              }
            }
          }
          {
            name: 'healthExtension'
            properties: {
              autoUpgradeMinorVersion: true
              enableAutomaticUpgrade: true
              forceUpdateTag: 'a'
              type: 'ApplicationHealthLinux'
              typeHandlerVersion: '1.0'
              publisher: 'Microsoft.ManagedServices'
              settings: {
                protocol: 'http'
                port: 3000
                requestPath: '/'
              }
            }
          }
        ]
      }
      osProfile: {
        computerNamePrefix: prefix
        adminUsername: adminUsername
        adminPassword: adminPassword
        linuxConfiguration: {
          disablePasswordAuthentication: true
          provisionVMAgent: true
          ssh: {
            publicKeys: [
              {
                keyData: sshPublicKey
                path: '/home/${adminUsername}/.ssh/authorized_keys'
              }
            ]
          }
        }
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: nicname
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: ipConfigName
                  properties: {
                    subnet: {
                      id: vmssSubnetId
                    }
                    applicationGatewayBackendAddressPools: [
                      {
                        id: appGatewayBePoolResourceId
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
    }
  }
}

resource logAnalyticsAgent 'Microsoft.Compute/virtualMachineScaleSets/extensions@2022-03-01' = {
  parent: vmss
  name: 'Microsoft.Insights.LogAnalyticsAgent'
  properties: {
    publisher: 'Microsoft.EnterpriseCloud.Monitoring'
    type: 'OmsAgentForLinux'
    typeHandlerVersion: '1.7'
    autoUpgradeMinorVersion: true
    settings: {
      workspaceId: workspaceId
    }
    protectedSettings: {
      workspaceKey: workspaceKey
    }
  }
}

resource existingStorage 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageAccountName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2021-04-01-preview' = {
  name: guid(resourceGroup().id, vmss.name, 'StorageDataContributor')
  scope: existingStorage
  properties: {
    principalId: vmss.identity.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: dataContributorRoleId
  }
}

resource appGatewayScaleSettings 'Microsoft.Insights/autoscalesettings@2022-10-01' = {
  name: autoScaleName
  location: location
  properties: {
    name: autoScaleName
    targetResourceUri: vmss.id
    enabled: true
    notifications: [
      {
        operation: 'Scale'
        email: {
          sendToSubscriptionAdministrator: false
          sendToSubscriptionCoAdministrators: false
        }
      }
    ]
    profiles: [
      {
        name: autoScaleName
        capacity: {
          minimum: '1'
          maximum: '10'
          default: '1'
        }
        rules: [
          {
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT1M'
            }
            metricTrigger: {
              metricName: 'AvgRequestCountPerHealthyHost'
              metricNamespace: 'microsoft.network/applicationgateways'
              metricResourceUri: appGatewayResourceId
              operator: 'GreaterThan'
              statistic: 'Average'
              threshold: 500
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT1M'
              dimensions: [
                {
                  DimensionName: 'BackendSettingsPool'
                  Operator: 'Equals'
                  Values: [
                    'backendPool~backendHttpsSettings'
                  ]
                }
              ]
              dividePerInstance: false
            }
          }
          {
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT1M'
            }
            metricTrigger: {
              metricName: 'AvgRequestCountPerHealthyHost'
              metricNamespace: 'microsoft.network/applicationgateways'
              metricResourceUri: appGatewayResourceId
              operator: 'LessThan'
              statistic: 'Average'
              threshold: 350
              timeAggregation: 'Average'
              timeGrain: 'PT1M'
              timeWindow: 'PT1M'
              dimensions: []
              dividePerInstance: false
            }
          }
        ]
      }
    ]
  }
}

/* resource vmssDiagnostics 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'vmss-diagnostics'
  scope: vmss
  properties: {
    workspaceId: workspaceResourceId
    logs: [
      {
        category: null
        categoryGroup: 'allLogs'
        enabled: true
        retentionPolicy: {
          days: 30
          enabled: true
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        timeGrain: null
        enabled: false
        retentionPolicy: {
          days: 0
          enabled: false
        }
      }
    ]
  }
} */

/* resource autoScaleSettings 'microsoft.insights/autoscalesettings@2015-04-01' = {
  name: autoscaleName
  location: location
  properties: {
    name: autoscaleName
    targetResourceUri: vmss.id
    enabled: true
    profiles: [
      {
        name: 'Profile1'
        capacity: {
          minimum: '2'
          maximum: '10'
          default: '2'
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricNamespace: ''
              metricResourceUri: vmss.id
              timeGrain: 'PT1M'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 20
              statistic: 'Average'
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
          {
            metricTrigger: {
              metricName: 'Percentage CPU'
              metricNamespace: ''
              metricResourceUri: vmss.id
              timeGrain: 'PT1M'
              timeWindow: 'PT5M'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 5
              statistic: 'Average'
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT5M'
            }
          }
        ]
      }
    ]
  }
} */
