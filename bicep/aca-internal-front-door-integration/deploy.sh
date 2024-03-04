#!/bin/bash

SUB_DEPLOYMENT_LOCATION='australiaeast'
PREFIX='colour'
IMAGE_NAME='belstarr/colourserver-2' # replace <belstarr> with your own dockerHub username
IMAGE_TAG='0.1.4'
TLS_CERT_NAME='star-bellee-net'
PUBLIC_DOMAIN_NAME='bellee.net'
SUBDOMAIN_NAME='gateway'
PUBLIC_DNS_RESOURCE_GROUP='external-dns-zones-rg'
CURRENT_USER=$(az ad signed-in-user show --query id -o tsv)

# login to dockerhub, then build & push the container image
docker login
docker build -t "$IMAGE_NAME:$IMAGE_TAG" .
docker push "$IMAGE_NAME:$IMAGE_TAG"

# create key vault
KV_RG_NAME="${PREFIX}-kv-rg"
az group create --name $KV_RG_NAME --location $SUB_DEPLOYMENT_LOCATION

KEYVAULT_SCOPE=$(az deployment group create \
  --resource-group $KV_RG_NAME \
  --name kv-deployment \
  --template-file ./modules/keyvault.bicep \
  --parameters location=$SUB_DEPLOYMENT_LOCATION \
  --parameters prefix=$PREFIX \
  --parameters principalId=$CURRENT_USER \
  --query 'properties.outputs.id.value' -o tsv)

KV_NAME=$(az deployment group show \
  --resource-group $KV_RG_NAME \
  --name kv-deployment \
  --query 'properties.outputs.name.value' -o tsv)

# grant the runner of this script access to the key vault in order to upload the TLS certificate
az role assignment create --role 'Key Vault Administrator' --assignee $CURRENT_USER --scope $KEYVAULT_SCOPE

# upload public TLS certificate to keyvault
CERT_ID=$(az keyvault certificate import --vault-name $KV_NAME -n $TLS_CERT_NAME -f ./certs/$TLS_CERT_NAME.pfx --query sid -o tsv)

# deploy infrastructure
echo "deploying infrastructure"
az deployment sub create \
    --location $SUB_DEPLOYMENT_LOCATION \
    --name infra-deployment \
    --template-file ./main.bicep \
    --parameters prefix=${PREFIX} \
    --parameters imageName=${IMAGE_NAME} \
    --parameters imageTag=${IMAGE_TAG} \
    --parameters publicDomainName=$PUBLIC_DOMAIN_NAME \
    --parameters keyVaultName=$KV_NAME \
    --parameters keyVaultResourceGroupName=$KV_RG_NAME \
    --parameters subDomainName=$SUBDOMAIN_NAME \
    --parameters publicDnsResourceGroup=$PUBLIC_DNS_RESOURCE_GROUP

echo "testing frontDoor Fqdn: $PUBLIC_DOMAIN_NAME"
curl "https://$SUBDOMAIN_NAME.$PUBLIC_DOMAIN_NAME"
