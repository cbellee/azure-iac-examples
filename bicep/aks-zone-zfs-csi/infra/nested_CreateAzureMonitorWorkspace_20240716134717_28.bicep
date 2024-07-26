param tagsForAllResources object

resource defaultazuremonitorworkspace_eau 'microsoft.monitor/accounts@2023-04-03' = {
  name: 'defaultazuremonitorworkspace-eau'
  location: 'australiaeast'
  properties: {}
  tags: tagsForAllResources
}
