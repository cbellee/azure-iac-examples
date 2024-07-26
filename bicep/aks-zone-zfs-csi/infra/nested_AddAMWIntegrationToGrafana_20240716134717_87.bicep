resource grafana_20240716134621 'Microsoft.Dashboard/grafana@2022-08-01' = {
  location: 'australiaeast'
  name: 'grafana-20240716134621'
  properties: {
    grafanaIntegrations: {
      azureMonitorWorkspaceIntegrations: [
        {
          azureMonitorWorkspaceResourceId: '/subscriptions/b2375b5f-8dab-4436-b87c-32bc7fdce5d0/resourcegroups/aks-zone-zfs-test-rg/providers/Microsoft.monitor/accounts/defaultazuremonitorworkspace-eau'
        }
      ]
    }
  }
  sku: {
    name: 'Standard'
  }
}
