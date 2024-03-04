# AKS private link with Azure firewall scenario

[![Deploy To Azure](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.svg?sanitize=true)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2F301-aks-private-endpoint-firewall%2Fazuredeploy.json)

[![Visualize](https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/visualizebutton.svg?sanitize=true)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2FAzure%2Fazure-quickstart-templates%2Fmaster%2F301-aks-private-endpoint-firewall%2Fazuredeploy.json)    

### Overview

This solution deploys an AKS cluster with a private IP for the API server endpoint using Private Link.

### Architecture diagram

![aks-secure-architecture](https://github.com/cbellee/azure-iac-examples/blob/develop/arm/aks-private-endpoint-fw/images/secure-aks-architecture.png "AKS Secure Architecture")

The following resources are deployed as part of this solution

- Hub Virtual Network (10.0.0.0/16)
  - GatewaySubnet (10.0.0.0/24)
  - AzureFirewallSubnet (10.0.1.0/24)
  - ManagementSubnet (10.0.2.0/24)
- Spoke Virtual Network(10.1.0.0/16)
  - AKSSubnet (10.1.0.0/24)
- Virtual Network peering between hub and spoke virtual networks
- Azure Private Link endpoint for AKS
- Linux VM with private IP
- Azure Firewall
  - Inbound DNAT rule to allow access to the Linux VM from the internet on port 22
- Azure Monitor workspace for AKS container insights data

### Prerequisites
- Register Application Gateway Ingress Controller (AGIC) provider feature
`PS C:\> Register-AzProviderFeature -ProviderNamespace Microsoft.ContainerService -FeatureName AKS-IngressApplicationGatewayAddon`

### Script deployment
- Create an AAD group to use for RBAC admin access to the AKS and save the objectId of the group.
`PS C:\> $aadGroupObjectId = New-AzAdGroup -DisplayName '<AKS admin group name>' -PassThru | Select -ExpandProperty id`
- Add your AAD identity as a member of this group
`PS C:\> $aadUserObjectId = Get-AzAdUser -DisplayName '<your account name>' | Select -ExpandProperty id`
`PS C:\> Add-AzADGroupMember -MemberObjectId $aadUserObjectId -TargetGroupObject $aadGroupObjectId`
`PS C:\> ssh-keygen.exe # skip this step when using an existing key`  
`PS C:\> .\scripts\deploy.ps1 -aadAdminGroupObjectIds @($aadGroupObjectId) -sshPublicKey '<your ssh public key text>'`

### Scenario Deployment Validation
To validate that the AKS API service's private IP is accessible from the Linux VM. 
NOTE: kubectl & azure cli tools are automatically installed by cloud-init.
- SSH to the Azure Firewall public IP returned as output from the ARM deployment
  - `$ ssh localadmin@<Azure Firewall public IP>`
- Get the Kubernetes config file
  - `$ az login`
  - `$ az account set --subscription <your azure subscription id>`
  - `$ az aks get-credentials -g <aks resource group name> -n <aks cluster name> --admin`
- Test access by listing the current nodes & pods in the cluster
  - `$ kubectl get nodes`
  - `$ kubectl get pod -A`
