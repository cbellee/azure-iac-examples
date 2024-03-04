#!/bin/bash

LOCATION='australiaeast'
PREFIX='cbellee'
RG_NAME="aca-multi-${LOCATION}-rg"

# create resource group
az group create --location $LOCATION --name $RG_NAME

# deploy infrastructure
az deployment group create \
--resource-group $RG_NAME \
--name 'aca-multi-deployment' \
--template-file ./main.bicep \
--parameters location=$LOCATION \
--parameters prefix=$PREFIX \
--parameters sshKey="$(cat ~/.ssh/id_rsa.pub)"

VM_ID=$(az deployment group show \
--resource-group $RG_NAME \
--name 'aca-multi-deployment' \
--query properties.outputs.vmId.value -o tsv)

BASTION_NAME=$(az deployment group show \
--resource-group $RG_NAME \
--name 'aca-multi-deployment' \
--query properties.outputs.bastionName.value -o tsv)

APP_1_FQDN=$(az deployment group show \
--resource-group $RG_NAME \
--name 'aca-multi-deployment' \
--query properties.outputs.app1Fqdn.value -o tsv)

APP_2_FQDN=$(az deployment group show \
--resource-group $RG_NAME \
--name 'aca-multi-deployment' \
--query properties.outputs.app2Fqdn.value -o tsv)

az network bastion ssh \
	--resource-group $RG_NAME \
	--name $BASTION_NAME \
	--target-resource-id $VM_ID \
	--auth-type ssh-key \
	--username localadmin \
	--ssh-key ~/.ssh/id_rsa

# in SSH session on a VM run the following commands
nslookup <APP 1 FQDN>
curl https://<APP 1 FQDN>

nslookup <APP 2 FQDN>
curl https://<APP 2 FQDN>