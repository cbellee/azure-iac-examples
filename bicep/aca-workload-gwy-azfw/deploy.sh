RG_NAME='aca-workload-profiles-rg'
LOCATION="northcentralus"
IMAGE_TAG='mcr.microsoft.com/azuredocs/containerapps-helloworld:latest'
DOMAIN_NAME='kainiindustries.net' # replace with your public domain name
PUBLIC_PFX_CERT_FILE="./certs/star.${DOMAIN_NAME}.bundle.pfx"
PUBLIC_PFX_CERT_NAME='public-certificate-pfx'
PUBLIC_DNS_ZONE_RESOURCE_GROUP='external-dns-zones-rg'
APP_NAME='aca-hello-world'

# load vars from /.env file. 
# the following env vars should be defined within the file
#
# PUBLIC_CERT_PASSWORD='<your PFX certificate secret>'
# ADMIN_GROUP_OBJECT_ID=<your AAD AKS admin group name>

source ./.env

# create resource group
az group create --name $RG_NAME --location $LOCATION

# deploy key vault
az deployment group create \
  --resource-group $RG_NAME \
  --name kv-deployment \
  --template-file ./modules/keyVault.bicep \
  --parameters keyVaultAdminObjectId=$ADMIN_GROUP_OBJECT_ID \
  --parameters location=$LOCATION

# get keyvault name
KV_NAME=$(az deployment group show --resource-group $RG_NAME --name kv-deployment --query 'properties.outputs.keyVaultName.value' -o tsv)

# upload public tls certificate to Key Vault
PUBLIC_CERT_PROPS=$(az keyvault certificate import --vault-name $KV_NAME -n $PUBLIC_PFX_CERT_NAME -f $PUBLIC_PFX_CERT_FILE --password $PUBLIC_CERT_PASSWORD)
PUBLIC_CERT_SID=$(echo $PUBLIC_CERT_PROPS | jq .sid -r)

# deploy resources
az deployment group create \
--resource-group $RG_NAME \
--name 'aca-dedicated-deployment' \
--template-file ./main.bicep \
--parameters imageName=$IMAGE_TAG \
--parameters location=$LOCATION \
--parameters tlsCertSecretId="$PUBLIC_CERT_SID" \
--parameters domain=$DOMAIN_NAME \
--parameters keyVaultName=$KV_NAME \
--parameters publicDnsZoneResourceGroup=$PUBLIC_DNS_ZONE_RESOURCE_GROUP \
--parameters containerAppName=$APP_NAME \
--parameters dnsHostName=$APP_NAME

 curl "https://${APP_NAME}.${DOMAIN_NAME}"

 curl https://aca-todolist-demo.braveground-c7fa82d3.westeurope.azurecontainerapps.io/api/todos
