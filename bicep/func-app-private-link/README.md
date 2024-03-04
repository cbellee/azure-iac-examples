# Function app with private link ingress & vnet integrated egress
## Overview
This set of bicep templates create the following Azure resources:
- App Service Elastic Premium Plan
- Function app
- Virtual network
- Private endpoint for function app ingress
- Private DNS for function app ingress
- Azure Bastion (to access the internal Windows VM)
- Windows VM (for testing connectivity to the private endpoint)
- Application Insights
- Private endpoints for Function app storage account endpoints (blob, table, queue & file)
- Private DNS zones for Function app storage account endpoints (blob, table, queue & file)

## Prerequisites
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- Bash shell (Native Mac/Linux shell or Windows Susbsystem for Linux)
## Usage
- create /.env file in the root directory
- add a line to the file specifying the VM admin password environment variable & value
  - `VM_ADMIN_PASSWORD='<VM password>'`
- change working directory to 'scripts'
  - `$ cd ./scripts`
- execute the deployment script 
  - `$ ./deploy.sh`