LOCATION='australiaeast'
POOL_NAME='ado-vmss-agent-pool'
RG_NAME='ado-vmss-agent-pool-rg'
VNET_NAME='ado-vmss-agent-pool-vnet'
UMID_NAME='dev-ado-umid'
VMSS_IMAGE_NAME='Ubuntu2204'
ADO_PROJECT_NAME='Terraform AKS Federated Identity'
ADO_SERVICE_CONNECTION_NAME='tf-aks-ado-service-cxn-2'
SUBSCRIPTION_ID="b2375b5f-8dab-4436-b87c-32bc7fdce5d0"
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
BACKEND_STORAGE_ACCOUNT_RG='tf-state-rg'
STORAGE_ACCOUNT_NAME='tfstatestorcbellee452023'
AAD_AKS_ADMIN_GROUP_ID=$(az ad group show -g aks-admin-group --query id -o tsv)

# add these vars to ./env file before running this script
# AAD_AKS_ADMIN_GROUP_ID=<your AAD group Object Id>
# ADO_ORG_ID=<your ADO org GUID>
# ADO_ORG_URL=https://dev.azure.com/<your ADO org name>

source ../.env 

ISSUER="https://vstoken.dev.azure.com/$ADO_ORG_ID"
SUBJECT="sc://kainidev/$ADO_PROJECT_NAME/$ADO_SERVICE_CONNECTION_NAME"
AUDIENCE='api://AzureADTokenExchange'

az login
az account set -s $SUBSCRIPTION_ID
az group create --name $RG_NAME --location $LOCATION

BACKEND_STORAGE_ACCOUNT_ID=$(az storage account show --resource-group $BACKEND_STORAGE_ACCOUNT_RG --name $STORAGE_ACCOUNT_NAME --query id -o tsv)
UMID_CLIENT_RESOURCE_ID=$(az identity create --name $UMID_NAME --resource-group $RG_NAME --query id --output tsv)

sleep 10

UMID_PRINCIPAL_ID=$(az identity show -n $UMID_NAME -g $RG_NAME --query principalId --out tsv)
UMID_CLIENT_ID=$(az identity show -n $UMID_NAME -g $RG_NAME --query clientId --out tsv)
az role assignment create --assignee $UMID_PRINCIPAL_ID --role 'Owner' --scope "$BACKEND_STORAGE_ACCOUNT_ID"
az role assignment create --assignee $UMID_PRINCIPAL_ID --role 'Owner' --scope "/subscriptions/$SUBSCRIPTION_ID"

az devops project create \
    --name "$ADO_PROJECT_NAME" \
    --org $ADO_ORG_URL \
    --source-control git \
    --process agile

# TODO: open the new project & manually create an azure devops service connection
az devops project show \
    --project "$ADO_PROJECT_NAME" \
    --org $ADO_ORG_URL \
    --open

# get the following details from the service connection
# navigate to Project Settings / Service connections / Service Connection Name / Manage Service Principal
# Issuer: https://vstoken.dev.azure.com/xxxxxxxxxxxxx-xxxxx-xxxxx-xxxx-xxxxxxxxxxxx <- VSO Org ID GUID
# Subject identifier: sc://kainidev/Terraform AKS Federated Identity/tf-aks-ado-service-cxn <- service cxn name

az identity federated-credential create \
    --identity-name $UMID_NAME \
    --name fed-cred \
    --resource-group $RG_NAME \
    --audiences "$AUDIENCE" \
    --issuer "$ISSUER" \
    --subject "$SUBJECT"

az network vnet create \
    --name $VNET_NAME \
    --resource-group $RG_NAME \
    --address-prefix '10.1.0.0/16' \
    --subnet-name vmss-subnet \
    --subnet-prefixes '10.1.1.0/24'

SUBNET_ID=$(az network vnet subnet create \
    --name aks-subnet \
    --resource-group $RG_NAME \
    --vnet-name $VNET_NAME \
    --address-prefixes '10.1.0.0/24' \
    --query id -o tsv)

BASTION_SUBNET_ID=$(az network vnet subnet create \
    --name AzureBastionSubnet \
    --resource-group $RG_NAME \
    --vnet-name $VNET_NAME \
    --address-prefixes '10.1.2.0/24' \
    --query id -o tsv)

az network public-ip create \
    --name bastion-ip \
    --resource-group $RG_NAME \
    --location $LOCATION \
    --sku Standard

az network bastion create \
    --name ado-vmss-bastion \
    --public-ip-address bastion-ip \
    --resource-group $RG_NAME \
    --vnet-name $VNET_NAME \
    --enable-tunneling true \
    --location $LOCATION

# create aks cluster
az aks create \
    --resource-group $RG_NAME \
    --name ado-vmss-aks \
    --node-count 1 \
    --network-plugin azure \
    --vnet-subnet-id $SUBNET_ID \
    --generate-ssh-keys \
    --enable-managed-identity \
    --enable-workload-identity \
    --enable-oidc-issuer \
    --disable-local-accounts \
    --node-vm-size Standard_D4ads_v5 \
    --node-osdisk-size 100 \
    --enable-aad \
    --enable-azure-rbac \
    --aad-admin-group-object-ids "$AAD_AKS_ADMIN_GROUP_ID" \
    --aad-tenant-id $TENANT_ID \
    --enable-addons azure-policy \
    --network-plugin azure \
    --network-policy azure \
    --enable-cluster-autoscaler \
    --enable-private-cluster \
    --min-count 1 \
    --max-count 3 \
    --load-balancer-sku standard

az aks update \
    --resource-group $RG_NAME \
    --name ado-vmss-aks \
    --enable-workload-identity \
    --enable-oidc-issuer

# get aks cluster id & assign 'Azure Kubernetes Service RBAC Writer' role to the umid
AKS_RESOURCE_ID=$(az aks show -g $RG_NAME -n ado-vmss-aks --query id -o tsv)
az role assignment create --assignee $UMID_PRINCIPAL_ID --role 'Azure Kubernetes Service RBAC Writer' --scope $AKS_RESOURCE_ID
az role assignment create --assignee $UMID_PRINCIPAL_ID --role 'Azure Kubernetes Service Cluster Admin Role' --scope $AKS_RESOURCE_ID

VMSS_SUBNET_ID=$(az network vnet subnet show \
    --name vmss-subnet \
    --resource-group $RG_NAME \
    --vnet-name $VNET_NAME \
    --query id -o tsv)

# create vmss for ado agent pool
# cloud-init configuration installs the latest 'terraform' binary
az vmss create \
    --name $POOL_NAME \
    --resource-group $RG_NAME \
    --image $VMSS_IMAGE_NAME \
    --vm-sku Standard_D4ads_v5 \
    --storage-sku StandardSSD_LRS \
    --subnet $VMSS_SUBNET_ID \
    --admin-username localadmin \
    --orchestration-mode Uniform \
    --authentication-type SSH \
    --instance-count 1 \
    --disable-overprovision \
    --upgrade-policy-mode manual \
    --single-placement-group false \
    --platform-fault-domain-count 1 \
    --load-balancer "" \
    --assign-identity $UMID_CLIENT_RESOURCE_ID \
    --ssh-key-values ~/.ssh/id_rsa.pub \
    --custom-data cloud-init

# TODO: create a DevOps Agent Pool and add the vmss to it
# create an ADO Agent pool targeted at the VMSS previously created, in the ADO portal

# SSH to vm instance & install pre-requisite tools (cloud-init doesn't seem to work...)
# get first vmss instance resourceId
FIRST_VMSS_INSTANCE=$(az vmss list-instances -g $RG_NAME -n $POOL_NAME | jq .[0].id -r)

az network bastion ssh \
    --name ado-vmss-bastion \
    --auth-type ssh-key \
    --username localadmin \
    --resource-group $RG_NAME \
    --target-resource-id $FIRST_VMSS_INSTANCE \
    --ssh-key ~/.ssh/id_rsa

