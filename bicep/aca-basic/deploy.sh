LOCATION='australiaeast'
PREFIX='cbellee'
RG_NAME="aca-test-rg"
IMAGE_NAME='envvars'
IMAGE_VERSION='latest'
PORT=8080

# create resource group
az group create --location $LOCATION --name $RG_NAME

ACR_NAME=$(az acr create \
    --resource-group $RG_NAME \
    --name "${PREFIX}2830743" \
    --location $LOCATION \
    --sku Standard \
    --query name -o tsv)

docker build . -t $ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_VERSION
# docker pull nginx:latest
az acr login --name $ACR_NAME
docker push $ACR_NAME.azurecr.io/$IMAGE_NAME:$IMAGE_VERSION

# deploy infrastructure
az deployment group create \
    --resource-group $RG_NAME \
    --name 'aca-test-deployment' \
    --template-file ./main.bicep \
    --parameters location=$LOCATION \
    --parameters acrName=$ACR_NAME \
    --parameters prefix=$PREFIX \
    --parameters port=$PORT \
    --parameters containerImageName=$IMAGE_NAME \
    --parameters containerImageTag=$IMAGE_VERSION
