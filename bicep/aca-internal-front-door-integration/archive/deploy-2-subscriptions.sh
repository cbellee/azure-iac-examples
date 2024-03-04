#!/bin/bash
CXN_SUB_ID='cbbe3aae-02d5-4c56-aed9-6a253cb54019'
ACA_SUB_ID='b2375b5f-8dab-4436-b87c-32bc7fdce5d0'
LOCATION='australiaeast'
PREFIX='afd'
RG_NAME="${PREFIX}-aca-rg"
CXN_RG_NAME="${PREFIX}-aca-cxn-rg"

# deploy infrastructure
az deployment sub create \
    --location $LOCATION \
    --subscription $ACA_SUB_ID \
	--name 'infra-deployment' \
	--template-file ./main-workload-sub.bicep \
	--parameters location=$LOCATION \
    --parameters resourceGroupName=$RG_NAME \
    --parameters remoteSubscriptionId=$ACA_SUB_ID
    # --parameters remoteSubscriptionId=$CXN_SUB_ID

# get deployment template outputs
ACA_ENV_PRIVATE_IP=$(az deployment sub show --subscription $ACA_SUB_ID --name 'infra-deployment' --query properties.outputs.containerAppEnvironmentPrivateIpAddress.value --output tsv)
ACA_APP_FQDN=$(az deployment sub show --subscription $ACA_SUB_ID --name 'infra-deployment' --query properties.outputs.containerAppFqdn.value --output tsv)
ACA_APP_ENV_MANAGED_RG_NAME=$(az deployment sub show --subscription $ACA_SUB_ID --name 'infra-deployment' --query properties.outputs.managedResourceGroupName.value --output tsv)
ACA_APP_ENV_RG_NAME=$(az deployment sub show --subscription $ACA_SUB_ID --name 'infra-deployment' --query properties.outputs.resourceGroupName.value --output tsv)
ACA_APP_ENV_VNET_NAME=$(az deployment sub show --subscription $ACA_SUB_ID --name 'infra-deployment' --query properties.outputs.vnetName.value --output tsv)

# deploy connectivity subscription resources
az deployment sub create \
    --location $LOCATION \
    --subscription $CXN_SUB_ID \
	--name 'cxn-infra-deployment' \
	--template-file ./main-connectivity-sub.bicep \
    --parameters resourceGroupName=$CXN_RG_NAME \
	--parameters location=$LOCATION \
    --parameters remoteSubscriptionId=$ACA_SUB_ID \
    --parameters containerAppFqdn=$ACA_APP_FQDN \
    --parameters appEnvironmentManagedResourceGroupName=$ACA_APP_ENV_MANAGED_RG_NAME \
    --parameters appEnvironmentResourceGroupName=$RG_NAME \
    --parameters workloadVnetName=$ACA_APP_ENV_VNET_NAME

PLS_NAME=$(az deployment sub show --subscription $ACA_SUB_ID --resource-group $RG_NAME --name 'cxn-infra-deployment' --query properties.outputs.privateLinkServiceName.value --output tsv)
AFD_FQDN=$(az deployment group show --subscription $ACA_SUB_ID --resource-group $RG_NAME --name 'cxn-infra-deployment' --query properties.outputs.afdFqdn.value --output tsv)
# PEC_ID=$(az network private-endpoint-connection list -g $RG_NAME -n $PLS_NAME --type Microsoft.Network/privateLinkServices --query [0].id --output tsv)

# approve private endpoint connection
# echo "approving private endpoint connection ID: '$PEC_ID'"
# az network private-endpoint-connection approve -g $RG_NAME -n $PLS_NAME --id $PEC_ID --description "Approved" 

# wait for AFD settings to apply
sleep -s 60

# test AFD endpoint
curl "https://$AFD_FQDN" -v

# access conrainer app via VPN gateway & app environment private IP address
curl --resolve $ACA_APP_FQDN:443:$ACA_ENV_PRIVATE_IP https://$ACA_APP_FQDN -vk

