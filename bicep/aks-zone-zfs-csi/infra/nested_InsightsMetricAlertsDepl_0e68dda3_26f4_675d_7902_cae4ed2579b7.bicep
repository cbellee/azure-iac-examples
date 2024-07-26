param resourceId_Microsoft_Insights_ActionGroups_RecommendedAlertRules_AG_1 string
param tagsForAllResources object

resource CPU_Usage_Percentage_aks_zone_zfs_test 'microsoft.insights/metricAlerts@2018-03-01' = {
  name: 'CPU Usage Percentage - aks-zone-zfs-test'
  location: 'Global'
  properties: {
    severity: 3
    enabled: true
    scopes: [
      '/subscriptions/b2375b5f-8dab-4436-b87c-32bc7fdce5d0/resourcegroups/aks-zone-zfs-test-rg/providers/Microsoft.ContainerService/managedClusters/aks-zone-zfs-test'
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          name: 'Metric1'
          metricName: 'node_cpu_usage_percentage'
          metricNamespace: 'Microsoft.ContainerService/managedClusters'
          operator: 'GreaterThan'
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
          threshold: 95
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
    }
    targetResourceType: 'Microsoft.ContainerService/managedClusters'
    actions: [
      {
        actionGroupId: resourceId_Microsoft_Insights_ActionGroups_RecommendedAlertRules_AG_1
        webHookProperties: {}
      }
    ]
    tags: tagsForAllResources
  }
}

resource Memory_Working_Set_Percentage_aks_zone_zfs_test 'microsoft.insights/metricAlerts@2018-03-01' = {
  name: 'Memory Working Set Percentage - aks-zone-zfs-test'
  location: 'Global'
  properties: {
    severity: 3
    enabled: true
    scopes: [
      '/subscriptions/b2375b5f-8dab-4436-b87c-32bc7fdce5d0/resourcegroups/aks-zone-zfs-test-rg/providers/Microsoft.ContainerService/managedClusters/aks-zone-zfs-test'
    ]
    evaluationFrequency: 'PT5M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          name: 'Metric1'
          metricName: 'node_memory_working_set_percentage'
          metricNamespace: 'Microsoft.ContainerService/managedClusters'
          operator: 'GreaterThan'
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
          threshold: 100
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
    }
    targetResourceType: 'Microsoft.ContainerService/managedClusters'
    actions: [
      {
        actionGroupId: resourceId_Microsoft_Insights_ActionGroups_RecommendedAlertRules_AG_1
        webHookProperties: {}
      }
    ]
    tags: tagsForAllResources
  }
}
