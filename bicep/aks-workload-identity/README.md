# Project Summary

This project provides an example of deploying an Azure Kubernetes Service (AKS) cluster with workload identity using Bicep. Workload identity allows you to securely access Azure resources from within your AKS cluster without managing service principal credentials. This  docs article was used as a reference: [Use Microsoft Entra Workload ID with Azure Kubernetes Service (AKS)](https://learn.microsoft.com/en-us/azure/aks/workload-identity-overview?tabs=go).

The simple golang application is deployed to the AKS cluster and uses the Azure SDK for Go to access Azure Key Vault. The application is configured to use a user managed identity to access the storage account.

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
- [Azure Subscription](https://azure.microsoft.com/en-us/free/)
- SSH key pair

## Deployment Steps

- Clone the repository
- Login to Azure CLI
- Run the script to deploy the resources
  - `$ ./deploy.sh`
