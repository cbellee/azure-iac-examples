LOCATION='australiaeast'
POOL_NAME='ado-vmss-agent-pool'
RG_NAME='ado-vmss-agent-pool-rg'
VNET_NAME='ado-vmss-agent-pool-vnet'
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
UMID_NAME='dev-ado-umid'
VMSS_IMAGE_NAME='Ubuntu2204'
ISSUER='https://vstoken.dev.azure.com/301c0b1c-da21-4603-8a24-14a4bba9c2f5'
SUBJECT='sc://kainidev/ADO TF Federated Credential Example/example-federated-sc'
AUDIENCE='api://AzureADTokenExchange'
ADO_ORG_URL='https://dev.azure.com/kainidev'
ADO_PROJECT='Terraform AKS Federated Identity'
# ADO_PROJECT='ADO TF Federated Credential Example'

az account set -s $SUBSCRIPTION_ID
az group create --name $RG_NAME --location $LOCATION

UMID_CLIENT_ID=`az identity create --name $UMID_NAME --resource-group $RG_NAME --query id --output tsv`

sleep 10

UMID_PRINCIPAL_ID=$(az identity show -n $UMID_NAME -g $RG_NAME --query principalId --out tsv)
az role assignment create --assignee $UMID_PRINCIPAL_ID --role 'Owner' --scope /subscriptions/$SUBSCRIPTION_ID

az devops project create \
    --name "$ADO_PROJECT" \
    --org $ADO_ORG_URL \
    --source-control git \
    --process agile

# TODO: manually create an azure devops service connection
# and get the following details
# Issuer: https://vstoken.dev.azure.com/301c0b1c-da21-4603-8a24-14a4bba9c2f5
# Subject identifier: sc://kainidev/Terraform AKS Federated Identity/tf-aks-ado-service-cxn <- service cxn name

az identity federated-credential create \
    --identity-name $UMID_NAME \
    --name fed-cred-2 \
    --resource-group $RG_NAME \
    --audiences "api://AzureADTokenExchange" \
    --issuer "https://vstoken.dev.azure.com/301c0b1c-da21-4603-8a24-14a4bba9c2f5" \
    --subject "sc://kainidev/Terraform AKS Federated Identity/tf-aks-ado-service-cxn"

az network vnet create \
--name $VNET_NAME \
--resource-group $RG_NAME \
--address-prefix '10.1.0.0/16' \
--subnet-name vmss-subnet --subnet-prefixes '10.1.1.0/24'

# create vmss for ado agent pool
# cloud-init configuration installs the latest 'terraform' binary
az vmss create \
    --name $POOL_NAME \
    --resource-group $RG_NAME \
    --image $VMSS_IMAGE_NAME \
    --vm-sku Standard_D4ads_v5 \
    --storage-sku StandardSSD_LRS \
    --admin-username localadmin \
    --orchestration-mode Uniform \
    --authentication-type SSH \
    --instance-count 1 \
    --disable-overprovision \
    --upgrade-policy-mode manual \
    --single-placement-group false \
    --platform-fault-domain-count 1 \
    --load-balancer "" \
    --assign-identity  [system] $UMID_CLIENT_ID \
    --custom-data cloud-init.txt 

# TODO: create a DevOps Agent Pool and add the vmss


