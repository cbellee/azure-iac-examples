param reference_CreateGrafanaWorkspace_20240716134717_7_outputs_msiPrincipalId_value object

resource bf504e24_9bc2_e39a_155e_27466dbae69d 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: 'bf504e24-9bc2-e39a-155e-27466dbae69d'
  properties: {
    roleDefinitionId: '/subscriptions/b2375b5f-8dab-4436-b87c-32bc7fdce5d0/resourcegroups/aks-zone-zfs-test-rg/providers/microsoft.dashboard/grafana/grafana-20240716134621/providers/Microsoft.Authorization/roleDefinitions/43d0d8ad-25c7-4714-9337-8ba259a9fe05'
    principalId: reference_CreateGrafanaWorkspace_20240716134717_7_outputs_msiPrincipalId_value.outputs.msiPrincipalId.value
  }
}
