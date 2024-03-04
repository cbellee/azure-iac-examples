# AKS + Application Gateway Ingress Controller (AGIC)

Deploys an AKS cluster, an Azure Application Gateway v2 instance and configures the Kubernetes Application Gateway Ingress Controller components.

## Pre-requisites

- Azure Subscription
- Azure DevOps Account
- Azure CLI installed on local workstation
- Create an AAD Service Principal

  - `$ az ad sp create-for-rbac --skip-assignment`

## Usage

1. Import `azure-pipelines.yaml` into a new Azure pipeline

2. add the following variables using the YAML pipeline editor's 'variables' button

- aksServicePrincipalObjectId = `<Service Principal Object Id>`

- aksServicePrincipalAppId = `<Service Principal Application Id>`

- aksServicePrincipalSecret = `<Service Principal Secret>`
