# ARM template Deployment solution
  - Zone redundant Application Gateway v2 with Web Application Firewall
  - Zonal ILB App Service Environment
  - MariaDB or MySQLDB (HA zonal flex-server preview)
## Prerequisites
  - Developer Machine
    - clone & set cwd to repo root
    - Powershell 5.1+ (installed by default on Windows)
	  - Install on Linux [https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7.1](https://docs.microsoft.com/en-us/powershell/scripting/install/installing-powershell-core-on-linux?view=powershell-7.1)
	- Azure PowerShell Module
    - Azure CLI
	  - Install [https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-apt)
## Deployment Steps
 - Log into your Azure subscription using Azure PowerShell
   - `PS C:\> Login-AzAccount -Tenant <tenantId>`
   - `PS C:\> Set-AzAccount -SubscriptionId <subscriptionId>`
 - Log into your Azure Subscription using Azure CLI
   - `PS C:\> az login --tenant <tenantId>`
   - `PS C:\> az account set --subscription <subscriptionId>`
 - Execute the deployment script (assuming cwd is repo root)
   - `PS C:\> ./scripts/deploy.ps1 -Location 'australiaeast' -Prefix '<resource prefix>' -DomainName '<domain name>' -DbAdminPassword '<db admin password>'`

## Solution architecture

![https://github.com/cbellee/azure-iac-examples/blob/master/arm/appgwy-ilb-ase-zonal-sql-svcep/images/solution.png](https://github.com/cbellee/azure-iac-examples/blob/master/arm/appgwy-ilb-ase-zonal-sql-svcep/images/solution.png)


