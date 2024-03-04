#!/bin/bash

HASH_STRING=`echo "your_prefix" | md5sum | head -c 8`
STORAGE_ACCOUNT_NAME="tfstatestor${HASH_STRING}"
TF_STATE_RESOURCE_GROUP='tf-state-rg'
LOCATION='australiaeast'

# create terraform state storage account & containers for TF state files
az storage account create \
--name $STORAGE_ACCOUNT_NAME \
--resource-group $TF_STATE_RESOURCE_GROUP \
--location $LOCATION \
--sku Standard_LRS

az storage container create --name '10-network-tf-state' --account-name $STORAGE_ACCOUNT_NAME
az storage container create --name '20-compute-tf-state' --account-name $STORAGE_ACCOUNT_NAME
az storage container create --name '30-applicatiom-tf-state' --account-name $STORAGE_ACCOUNT_NAME

# set R/W RBAC for UMIDs
scope=$(az storage account show --name $STORAGE_ACCOUNT_NAME --resource-group $TF_STATE_RESOURCE_GROUP --query 'id' -o tsv)
networkContainerScope="$scope/blobServices/default/containers/10-network-tf-state"
computeContainerScope="$scope/blobServices/default/containers/20-compute-tf-state"
applicationContainerScope="$scope/blobServices/default/containers/30-application-tf-state"

NETWORK_SP=`az ad sp create-for-rbac --name 'network-sp' --role 'Storage Blob Data Contributor' --scopes $networkContainerScope | jq .appId -r`
COMPUTE_SP=`az ad sp create-for-rbac --name 'compute-sp' --role 'Storage Blob Data Contributor' --scopes $computeContainerScope | jq .appId -r`
APP_SP=`az ad sp create-for-rbac --name 'application-sp' --role 'Storage Blob Data Contributor' --scopes $applicationContainerScope | jq .appId -r`

# wait for Service Principals to be created
sleep -s 30

NETWORK_SP_PASSWORD=`az ad sp credential reset --id $(az ad sp show --id $NETWORK_SP --query id -o tsv) | jq .password -r`
COMPUTE_SP_PASSWORD=`az ad sp credential reset --id $(az ad sp show --id $COMPUTE_SP --query id -o tsv) | jq .password -r`
APP_SP_PASSWORD=`az ad sp credential reset --id $(az ad sp show --id $APP_SP --query id -o tsv) | jq .password -r`

az role assignment create --role 'Contributor' \
    --assignee-object-id $(az ad sp show --id $NETWORK_SP --query id -o tsv) \
    --scope '/subscriptions/b2375b5f-8dab-4436-b87c-32bc7fdce5d0'

az role assignment create --role 'Contributor' \
    --assignee-object-id $(az ad sp show --id $COMPUTE_SP --query id -o tsv) \
    --scope '/subscriptions/b2375b5f-8dab-4436-b87c-32bc7fdce5d0'

az role assignment create --role 'Contributor' \
    --assignee-object-id $(az ad sp show --id $APP_SP --query id -o tsv)\
    --scope '/subscriptions/b2375b5f-8dab-4436-b87c-32bc7fdce5d0'

az role assignment create --role 'Storage Blob Data Reader' \
    --assignee-object-id $(az ad sp show --id $COMPUTE_SP --query id -o tsv) \
    --scope $networkContainerScope

az role assignment create --role 'Storage Blob Data Reader' \
    --assignee-object-id $(az ad sp show --id $APP_SP --query id -o tsv) \
    --scope $computeContainerScope
