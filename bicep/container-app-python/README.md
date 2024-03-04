# Azure App Service container & PostGreSQL cross-region private-link demo

## Pre-requisites
- Bash shell
- Docker
- Azure subscription

## Deployment
- Clone this repo
- Create the file `/.env` & populate it with the following variables
  - `DB_ADMIN_PASSWORD='<your DB admin password>'`
  - `ADMIN_USER_OBJECT_ID='<key vault admin user objectId>'`
- Modify the following parameters in `/run.sh` to the desired Azure datacenter region names
  - `REGION_1='australiaeast'`
  - `REGION_2='uksouth'`
- Execute the script
  - `$ ./run.sh`
- The script will perform the following actions"
  - Deploy a resource group
  - Run a bicep template to deploy an Azure Container Registry (ACR)
  - Build & push the docker image containing the demo Python application to the ACR
  - Run a bicep template to deploy the following resources
    - 2 peered virtual networks - 1 per region
    - 2 PostGreSQL flexible servers - 1 per region
    - 2 App service plans & app instances - 1 per region
    - 2 Private DNS zones - 1 per region
- Finally, the script will execute an HTTP request against each app instance, which will return the private IP Address of the PostGreSQL server in the opposite region

