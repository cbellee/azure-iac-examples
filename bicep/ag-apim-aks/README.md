# Application Gateway, API Management, AKS example

This repo deploys an E2E solution to two expose APIs and a Javascript SPA, running in Kubernetes, to the Internet via Application Gateway & API Management.

The solution provisions the following resources:

- 2 x Virtual Networks (Hub & Spoke) with vNet peering
- Azure Application Gateway
- Azure API Management with Internal vNet integration
    - 2 x Open API definitions for each backend microservice
- AKS cluster
- Azure Monitor Workspace
- Network security groups for Application Gateway & API Management subnets
- Azure Container Registry
- Private DNS zone
- Public DNS records (existing public Azure DNS zone required)
- 2 x containerized Golang APIs ('product-api' & 'order-api') each generated from their own Open API definition files
- 1 x containerized React SPA front end application running in an NGINX container

# Pre-requisites

- Public SSL certificate with '`internal.<certificate root domain>`' as an additional Subject Alternative Name (SAN)
- [PowerShell](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.2)
- [Microsoft.Graph.Applications PowerShell module](https://docs.microsoft.com/en-us/powershell/microsoftgraph/installation?view=graph-powershell-1.0)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [Azure PowerShell Module](https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-8.1.0)
- `kubectl`
  - [Kubernetes Docs](https://kubernetes.io/docs/tasks/tools/)
  - [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/aks?view=azure-cli-latest#az-aks-install-cli) 
  - [PowerShell](https://docs.microsoft.com/en-us/powershell/module/az.aks/install-azakskubectl?view=azps-8.1.0)

# Deployment

- Change working directory to `./scripts`
  - `PS:\> cd ./scripts`
- Ensure you have AAD RBAC role to create:
  - Application registrations
  - Enterprise applications (service principals)
- Authenticate to the Azure cli & Azure Powershell
  - `PS:\scripts> az login -tenant <AAD Tenant Id GUID>`
  - `PS:\scripts> Connect-AzAccount -TenantId <AAD Tenant Id GUID>`
- Execute the script, passing the required parameters
  - `PS:\scripts> ./deploy.ps1 -Location <Azure region name> -AADTenant <AAD Tenant name> -PublicDnsZone <public Dns zone name> -CertificatePassword $(<Certificate password> | ConvertTo-SecureString -AsPlainText -Force) -AksAdminGroupObjectId <Aks Admin Group Object Id GUID> -CertificateName <.cer filename> -PfxCertificateName <.pfx filename>`


# Notes

