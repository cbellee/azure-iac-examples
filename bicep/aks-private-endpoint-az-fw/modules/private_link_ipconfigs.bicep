@description('private dns zone name')
param privateDnsZoneName string

@description('private endpoint Nic ipConfigurations array resource id')
param privateLinkNicResource string

module private_link_ipconfigs './private_link_ipconfigs_helper.bicep' = {
  name: 'private-link-ipconfigs'
  params: {
    privateDnsZoneName: privateDnsZoneName
    privateLinkNicIpConfigs: reference(privateLinkNicResource, '2019-11-01').ipConfigurations
  }
}
