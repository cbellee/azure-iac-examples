param resourceId_b2375b5f_8dab_4436_b87c_32bc7fdce5d0_aks_zone_zfs_test_rg_Microsoft_Insights_dataCollectionRules_MSCI_australiaeast_aks_zone_zfs_test string

resource aks_zone_zfs_test_microsoft_insights_ContainerInsightsExtension 'Microsoft.ContainerService/managedClusters/providers/dataCollectionRuleAssociations@2022-06-01' = {
  name: 'aks-zone-zfs-test/microsoft.insights/ContainerInsightsExtension'
  properties: {
    description: 'Association of data collection rule. Deleting this association will break the data collection for this AKS Cluster.'
    dataCollectionRuleId: resourceId_b2375b5f_8dab_4436_b87c_32bc7fdce5d0_aks_zone_zfs_test_rg_Microsoft_Insights_dataCollectionRules_MSCI_australiaeast_aks_zone_zfs_test
  }
}
