param tagsForAllResources object

resource MSProm_australiaeast_aks_zone_zfs_test 'Microsoft.Insights/dataCollectionEndpoints@2022-06-01' = {
  name: 'MSProm-australiaeast-aks-zone-zfs-test'
  location: 'australiaeast'
  kind: 'Linux'
  properties: {}
  tags: tagsForAllResources
}
