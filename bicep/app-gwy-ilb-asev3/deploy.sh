# bicep build ./main.bicep
PREFIX='cbellee'
RG="${PREFIX}-asev3-rg"
PRINCIPAL_ID=`az ad signed-in-user show --query id -o tsv`

source ./.env

az group create \
--name $RG \
--location australiaeast

KEYVAULT_NAME=`az deployment group create \
--template-file ./modules/keyvault.bicep \
--resource-group $RG \
--parameters prefix=$PREFIX \
--parameters principalId=$PRINCIPAL_ID \
--query properties.outputs.keyVaultName.value -o tsv`

CERT_OBJECT=`az keyvault certificate import \
--vault-name $KEYVAULT_NAME \
-n 'tls-cert' \
-f ./certs/star.kainiindustries.net.bundle.pfx \
--password $TLS_CERT_PASSWORD`

az deployment group create \
--template-file ./main.bicep \
--resource-group $RG \
--parameters aseName='cbellee-ilb-asev3'
