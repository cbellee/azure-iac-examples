# aks-vmss-slb

# Pre-requisites
1. 'Az' PowerShell module
2. Use the 'Set-AzContext' cmdlet to select your desired Azure Subscription

# Usage
From a PowerShell command prompt execute `./scripts/deploy.ps1`
Which will deploy the following resources

- Virtual Network
- AKS Cluster with VMSS, SLB & Managed Identity (no service principal required)
- Storage Account
- Azure Container Registry
