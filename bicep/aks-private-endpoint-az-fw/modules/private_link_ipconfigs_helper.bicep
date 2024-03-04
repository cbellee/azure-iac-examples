@description('private DNS zone name')
param privateDnsZoneName string

@description('private endpoint nic ip configuration array')
param privateLinkNicIpConfigs array

module nestedTemplate_private_link_ipconfigs_helper './dns_record.bicep' = [for (item, i) in privateLinkNicIpConfigs: {
  name: 'nestedTemplate-private-link-ipconfigs-helper${i}'
  params: {
    privateDnsZoneName: privateDnsZoneName
    privateLinkNicIpConfig: item
  }
}]
