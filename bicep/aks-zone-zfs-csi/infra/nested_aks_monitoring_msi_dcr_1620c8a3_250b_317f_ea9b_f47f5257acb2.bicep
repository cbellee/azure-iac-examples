@description('Specify the region for your OMS workspace.')
param workspaceRegion string

@description('Specifies the tags of the AKS cluster.')
param clusterTags object

@description('Specify the resource id of the OMS workspace.')
param omsWorkspaceId string

resource MSCI_australiaeast_aks_zone_zfs_test 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  location: workspaceRegion
  name: 'MSCI-australiaeast-aks-zone-zfs-test'
  tags: clusterTags
  kind: 'Linux'
  properties: {
    dataSources: {
      extensions: [
        {
          streams: [
            'Microsoft-ContainerInsights-Group-Default'
          ]
          extensionName: 'ContainerInsights'
          extensionSettings: {
            dataCollectionSettings: {
              interval: '5m'
              namespaceFilteringMode: 'Exclude'
              enableContainerLogV2: true
              namespaces: [
                'kube-system'
                'gatekeeper-system'
                'azure-arc'
              ]
            }
          }
          name: 'ContainerInsightsExtension'
        }
      ]
      syslog: []
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: omsWorkspaceId
          name: 'ciworkspace'
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-ContainerInsights-Group-Default'
        ]
        destinations: [
          'ciworkspace'
        ]
      }
    ]
  }
}
