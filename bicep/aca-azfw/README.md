# Azure Container App with Dapr
Simple 2 container + DPR example for the Azure container apps platform
- frontend: ReST api with dapr invocation input binding & servicebus output binding
- backend: ReST api with dapr servicebus input binding & cosmosdb output binding

## Prerequisites
  - Bash Shell (Linux or WSL 2)
  - [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
  - [make](http://www.gnu.org/software/make/)
  - [jq](https://stedolan.github.io/jq/)

## Azure deployment
The bicep template deployment creates the following Azure resources
- 1 x CosmosDB account, SQL database & container
- 1 x Azure Servicebus namespace & 1 x queue
- 1 x Azure Container Registry
- 1 x Azure Container App environment
- 2 x Azure Container Apps ('frontend' & 'backend')

Clone the repo
- `$ git clone git@github.com:cbellee/container-apps.git`

Build & push the container images
  - `$ make deploy_rg && make build`

Deploy the infrastructure 
  - `& make deploy`

Test API
  - `$ make test`

## Local dapr deployment with Azure backend 
Deploy the Azure backend resources 
  - `$ make deploy_rg && make build && make deploy`

Build and deploy the applications as executables locally in the Dapr CLI environment
  - `$ make build_local && make deploy_local`

Test local API 
  - `$ make test_local`
