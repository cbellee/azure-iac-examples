resource grafana_20240716134621 'microsoft.dashboard/grafana@2022-08-01' = {
  name: 'grafana-20240716134621'
  location: 'australiaeast'
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Standard'
  }
  properties: {}
}

output msiPrincipalId string = reference(grafana_20240716134621.id, '2022-08-01', 'Full').identity.principalId
