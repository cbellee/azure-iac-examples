#!/bin/bash

LOCATION='australiaeast'
PREFIX='cbellee'
RG_NAME="aca-internal-rg"

# create resource group
az group create --location $LOCATION --name $RG_NAME

# deploy Azure Container Registry
ACR_NAME=$(az deployment group create \
	--resource-group $RG_NAME \
	--name 'acr-deployment' \
	--template-file ./modules/acr.bicep \
	--parameters location=$LOCATION \
	--parameters prefix=$PREFIX \
	--query 'properties.outputs.name.value' \
	-o tsv)

# build container image in ACR
IMAGE_NAME="$ACR_NAME.azurecr.io/colourserver:latest"
az acr build -r $ACR_NAME -t $IMAGE_NAME .

# deploy infrastructure
az deployment group create \
	--resource-group $RG_NAME \
	--name 'aca-deployment' \
	--template-file ./main.bicep \
	--parameters location=$LOCATION \
	--parameters prefix=$PREFIX \
	--parameters sshKey="$(cat ~/.ssh/id_rsa.pub)" \
	--parameters imageName=$IMAGE_NAME \
	--parameters acrName=$ACR_NAME

VM_ID=$(az deployment group show \
--resource-group $RG_NAME \
--name 'aca-deployment' \
--query properties.outputs.vmId.value -o tsv)

BASTION_NAME=$(az deployment group show \
--resource-group $RG_NAME \
--name 'aca-deployment' \
--query properties.outputs.bastionName.value -o tsv)

APP_FQDN=$(az deployment group show \
--resource-group $RG_NAME \
--name 'aca-deployment' \
--query properties.outputs.app1Fqdn.value -o tsv)

# create SSH session to VM via Bastion
az network bastion ssh \
	--resource-group $RG_NAME \
	--name $BASTION_NAME \
	--target-resource-id $VM_ID \
	--auth-type ssh-key \
	--username localadmin \
	--ssh-key ~/.ssh/id_rsa

# in SSH session run the following commands
# nslookup $APP_FQDN
# curl https://$APP_FQDN
