# Routing requests based on JWT claims in Azure API Management

This example demonstrates how to route requests based on JWT claims in Azure API Management. The example uses 2 Azure AD tenants and a simple containerized application that returns either a 'blue' or 'green' web page response. The API Management service is configured to route requests to the correct tenant based on the user's `upn` claim.

## Prerequisites

- Azure subscription
- 2 Azure EntraID tenants with a test user in each tenant
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [jq](https://stedolan.github.io/jq/)

## Deployment

- modify the `deploy.sh` script with your Azure tenant details
- run `./deploy.sh`
