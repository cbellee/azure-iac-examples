# Terraform deployments using Managed Identity on Azure DevOps VMSS Self-Hosted Agents

### Overview

Deploying workloads to a private AKS cluster prevents the use of Azure DevOps Microsoft-hosted agents, since the API server now sits behind a private IP. This example demonstrates how to deploy an ADO managed Azure VM Scale-set on which to self-host the ADO agents and authenticate to different Azure subscriptions using dedicated user-managed identities which are assigned RBAC rights to the subscriptions.

### Requirements

- 2 Azure subscriptions in the same AAD tenant
- Azure DevOps account
- Bash shell
- Azure CLI

## Deploy VM Scaleset

/ado-vmss/deploy.sh creates a VM scaleset with the necessary software (Terraform CLI) installed. 
note: The script creates 2 User-Managed Identities and assigns each of them 'Owner' RBAC permissions on the respective subscriptionIds set using the variables mentioned below.

- First, modify the following variables within the /ado-vmss/deploy.sh script
  - LOCATION='your Azure region'
  - POOL_NAME='your ADO VMSS pool name'
  - RG_NAME='your ADO VMSS resource group name'
  - VNET_NAME='your ADO VMSS virtual network name'
  - DEV_SUBSCRIPTION_ID='your Dev subscriptionId'
  - TEST_SUBSCRIPTION_ID='your Test subscriptionId'
- Next, execute the /ado-vmss/deploy.sh script

NOTE: The VMSS is provisioned using a cloud-init file (show below) to install Terraform and other dependencies

```bash
#cloud-config
package_upgrade: true
packages:
  - unzip
  - software-properties-common 
  - gnupg2
  - curl
runcmd:
  - 'curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -'
  - 'apt-add-repository "deb [arch=$(dpkg --print-architecture)] https://apt.releases.hashicorp.com $(lsb_release -cs) main"'
  - 'apt update'
  - 'apt install terraform'
```

## Connect the VMSS to your ADO account as a new self-hosted agent pool

- Create a new [ADO Service Connection for Azure Resource Manager](https://learn.microsoft.com/en-us/azure/devops/pipelines/library/connect-to-azure?view=azure-devops#create-an-azure-resource-manager-service-connection-to-a-vm-with-a-managed-service-identity ) using the 'Managed Identity' option
- Manually [create a new ADO VMSS Agent Pool](https://learn.microsoft.com/en-us/azure/devops/pipelines/agents/scale-set-agents?view=azure-devops) in the ADO portal
  - NOTE: in order to successfully choose the VMSS in the subscription/resource group, you must use an existing ADO Service Connection configured with Service Principal/Secret authentication.
- Modify variables in the /azure-pipelines.yaml file
  - name: ADO_SERVICE_CONNECTION_NAME
    - value: 'your managed identity enabled ADO service connection name'
  - name: devSubscriptionId
    - value: 'your dev subscriptionId'
  - name: testSubscriptionId
    - value: 'your test subscriptionId'
  - name: devClientId
    - value: 'your dev User-Managed Identity clientId' # value of $DEV_UMID_ID script variable
  - name: testClientId
    - value: 'your test User-Managed Identity clientId' # value of $TEST_UMID_ID script variable
  - name: tenantId
    - value: 'your AAD tenantId'

- [Import the /azure-pipelines.yaml definition](https://learn.microsoft.com/en-us/azure/devops/pipelines/get-started/clone-import-pipeline?view=azure-devops&tabs=yaml#export-and-import-a-pipeline) into Azure DevOps
- Execute the pipeline to provision a private AKS to each subscription
