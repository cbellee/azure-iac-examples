RG_NAME='aca-fw-test-2-rg'
LOCATION='australiaeast'
ENVIRONMENT='dev'
VERSION='0.1.0'
TAG="${ENVIRONMENT}-${VERSION}"
DB_ADMIN_USERNAME='dbadmin'
FRONTEND_PORT='80'
BACKEND_PORT='81'

az group create --location $LOCATION --name $RG_NAME

az deployment group create \
    --resource-group $RG_NAME \
    --name 'acr-deployment' \
    --template-file ./infra/modules/acr.bicep

ACR_NAME=$(az deployment group show \
    --resource-group $RG_NAME \
    --name 'acr-deployment' \
    --query properties.outputs.acrName.value -o tsv)

az acr build \
    --registry $ACR_NAME \
    --image "$ACR_NAME.azurecr.io/frontend:$TAG" \
    --build-arg SERVICE_NAME="frontend" \
    --build-arg SERVICE_PORT=$FRONTEND_PORT  \
    -f Dockerfile .

az acr build \
    --registry $ACR_NAME \
    --image "$ACR_NAME.azurecr.io/backend:$TAG" \
    --build-arg SERVICE_NAME="backend" \
    --build-arg SERVICE_PORT=$BACKEND_PORT \
    -f Dockerfile .

az deployment group create \
    --resource-group $RG_NAME \
    --name 'infra-deployment' \
    --template-file ./infra/main.bicep \
    --parameters location=$LOCATION \
    --parameters imageTag=$TAG \
    --parameters frontendAppPort=$FRONTEND_PORT \
    --parameters backendAppPort=$BACKEND_PORT \
    --parameters acrName=$ACR_NAME

FRONT_END_FQDN=$(az deployment group show \
    --resource-group $RG_NAME \
    --name 'infra-deployment' \
    --query properties.outputs.frontendFqdn.value -o tsv)

curl https://$FRONT_END_FQDN/checkin -X POST -d '{"user_id":"777","location_id":"77"}'
