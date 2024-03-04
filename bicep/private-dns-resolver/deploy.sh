#!/bin/bash

LOCATION='australiaeast'
RG_NAME="dns-private-resolver-rg"
LOCAL_GATEWAY_PUBLIC_IP_ADDRESS=$(curl ifconfig.me)
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)

# load the .env variable file
source ./.env

# create resource group
az group create --name $RG_NAME --location $LOCATION

# deploy solution
az deployment group create \
    --name 'infra-deployment' \
    --resource-group $RG_NAME \
    --template-file ./main.bicep \
    --parameters location=$LOCATION \
    --parameters vpnSharedKey=$VPN_SHARED_KEY \
    --parameters localGatewayPublicIpAddress=$LOCAL_GATEWAY_PUBLIC_IP_ADDRESS \
    --parameters sshKey="$SSH_KEY"
