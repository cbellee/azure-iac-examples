REGION_1='canadacentral'
REGION_2='uksouth'
NAME='pytn'
RG_NAME="${NAME}-rg"
COMMIT=$(git rev-parse --short HEAD)
IMAGE_TAG="v0.0.1-${COMMIT}"
IMAGE_NAME="${NAME}-app:${IMAGE_TAG}"
CONTAINER_PORT='80'
ADMIN_USER_OBJECT_ID=$(az ad signed-in-user show --query objectId -o tsv)

# load the following env vars defined in an .env file in the same directory as this file (run.sh)
# DB_ADMIN_PASSWORD=<your database administrator password>

. ./.env

# create resource group
az group create -l $REGION_1 -n $RG_NAME

# deploy Azure container Registry
az deployment group create \
    --resource-group $RG_NAME \
    --name acr-deployment \
    --template-file ./infra/modules/acr.bicep \
    --parameters location=$REGION_1 \
    --parameters name=$NAME \
    --parameters sku='Premium'

# get ACR details from 'acr-deployment'
ACR_NAME=$(az deployment group show -n acr-deployment -g $RG_NAME --query properties.outputs.name.value -o tsv)
ACR_LOGIN_SERVER=$(az deployment group show -n acr-deployment -g $RG_NAME --query properties.outputs.loginServer.value -o tsv)
ACR_PASSWORD=$(az acr credential show --name $ACR_NAME --query 'passwords[0].value' -o tsv)

# build and push container
docker build --platform linux/amd64 -t "${ACR_LOGIN_SERVER}/${IMAGE_NAME}" ./app
docker login -u $ACR_NAME -p $ACR_PASSWORD $ACR_LOGIN_SERVER
docker push $ACR_LOGIN_SERVER/$IMAGE_NAME

# infra deployment
az deployment group create \
    --resource-group $RG_NAME \
    --name infra-deployment \
    --template-file ./infra/main.bicep \
    --parameters name=$NAME \
    --parameters region1=$REGION_1 \
    --parameters region2=$REGION_2 \
    --parameters acrName=$ACR_NAME \
    --parameters acrPassword=$ACR_PASSWORD \
    --parameters acrLoginServer=$ACR_LOGIN_SERVER \
    --parameters containerImage="${ACR_LOGIN_SERVER}/${IMAGE_NAME}" \
    --parameters containerPort=$CONTAINER_PORT \
    --parameters dbAdminUserName='dbadmin' \
    --parameters dbAdminPassword=$DB_ADMIN_PASSWORD \
    --parameters adminUserObjectId=$ADMIN_USER_OBJECT_ID

APP_REVISION_URL=$(az deployment group show -n infra-deployment -g $RG_NAME --query properties.outputs.latestRevisionFqdn.value -o tsv)

# ensure the app (canadacentral) connects to the databse server ip of the opposite region (uk south)
curl https://$APP_REVISION_URL/info

