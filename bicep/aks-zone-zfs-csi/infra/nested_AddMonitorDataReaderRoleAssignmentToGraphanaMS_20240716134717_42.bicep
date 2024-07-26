param reference_CreateGrafanaWorkspace_20240716134717_7_outputs_msiPrincipalId_value object

resource _542c335b_1bc6_b316_a1c3_59792044d58f 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: '/subscriptions/b2375b5f-8dab-4436-b87c-32bc7fdce5d0/resourcegroups/aks-zone-zfs-test-rg/providers/Microsoft.monitor/accounts/defaultazuremonitorworkspace-eau'
  name: '542c335b-1bc6-b316-a1c3-59792044d58f'
  properties: {
    roleDefinitionId: '/subscriptions/b2375b5f-8dab-4436-b87c-32bc7fdce5d0/resourcegroups/aks-zone-zfs-test-rg/providers/Microsoft.monitor/accounts/defaultazuremonitorworkspace-eau/providers/Microsoft.Authorization/roleDefinitions/b0d8363b-8ddd-447d-831f-62ca05bff136'
    principalId: reference_CreateGrafanaWorkspace_20240716134717_7_outputs_msiPrincipalId_value.outputs.msiPrincipalId.value
  }
}
