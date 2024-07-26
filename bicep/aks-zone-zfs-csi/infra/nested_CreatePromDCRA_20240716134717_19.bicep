resource ContainerInsightsMetricsExtension 'Microsoft.Insights/dataCollectionRuleAssociations@2022-06-01' = {
  scope: '/subscriptions/b2375b5f-8dab-4436-b87c-32bc7fdce5d0/resourcegroups/aks-zone-zfs-test-rg/providers/microsoft.containerservice/managedclusters/aks-zone-zfs-test'
  name: 'ContainerInsightsMetricsExtension'
  properties: {
    description: 'Association of data collection rule. Deleting this association will break the prometheus metrics data collection for this AKS Cluster.'
    dataCollectionRuleId: '/subscriptions/b2375b5f-8dab-4436-b87c-32bc7fdce5d0/resourcegroups/aks-zone-zfs-test-rg/providers/Microsoft.Insights/dataCollectionRules/MSProm-australiaeast-aks-zone-zfs-test'
  }
}
