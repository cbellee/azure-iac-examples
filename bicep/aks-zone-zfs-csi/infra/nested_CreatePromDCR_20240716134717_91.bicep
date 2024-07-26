param tagsForAllResources object

resource MSProm_australiaeast_aks_zone_zfs_test 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  location: 'australiaeast'
  name: 'MSProm-australiaeast-aks-zone-zfs-test'
  kind: 'Linux'
  properties: {
    dataCollectionEndpointId: '/subscriptions/b2375b5f-8dab-4436-b87c-32bc7fdce5d0/resourceGroups/aks-zone-zfs-test-rg/providers/Microsoft.Insights/dataCollectionEndpoints/MSProm-australiaeast-aks-zone-zfs-test'
    dataSources: {
      prometheusForwarder: [
        {
          name: 'PrometheusDataSource'
          streams: [
            'Microsoft-PrometheusMetrics'
          ]
          labelIncludeFilter: {}
        }
      ]
    }
    destinations: {
      monitoringAccounts: [
        {
          accountResourceId: '/subscriptions/b2375b5f-8dab-4436-b87c-32bc7fdce5d0/resourcegroups/aks-zone-zfs-test-rg/providers/Microsoft.monitor/accounts/defaultazuremonitorworkspace-eau'
          name: 'MonitoringAccount1'
        }
      ]
    }
    dataFlows: [
      {
        destinations: [
          'MonitoringAccount1'
        ]
        streams: [
          'Microsoft-PrometheusMetrics'
        ]
      }
    ]
  }
  tags: tagsForAllResources
}
