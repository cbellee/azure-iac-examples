LOCATION='australiaeast'
PREFIX='cbellee'
RG_NAME="aca-test-rg"
CURRENT_USER=$($(az ad signed-in-user show --query id -o tsv))

# create resource group
az group create --location $LOCATION --name $RG_NAME

ACR_NAME=$(az acr create \
    --resource-group $RG_NAME \
    --name "${PREFIX}2830743" \
    --location $LOCATION \
    --sku Standard \
    --query name -o tsv)

docker pull nginx:latest
az acr login --name $ACR_NAME

# create role assignments
az role assignment create --assignee $CURRENT_USER --role acrpull --scope /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RG_NAME/providers/Microsoft.ContainerRegistry/registries/$ACR_NAME
az role assignment create --assignee $CURRENT_USER --role acrpush --scope /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RG_NAME/providers/Microsoft.ContainerRegistry/registries/$ACR_NAME

az acr import --name $ACR_NAME -g $RG_NAME --source docker.io/library/nginx:latest --image nginx:latest --verbose

# deploy infrastructure
az deployment group create \
    --resource-group $RG_NAME \
    --name 'aca-test-deployment' \
    --template-file ./main.bicep \
    --parameters location=$LOCATION \
    --parameters acrName=$ACR_NAME \
    --parameters prefix=$PREFIX \
    --parameters containerImageName='nginx' \
    --parameters containerImageTag='latest' \
    --parameters secretValue='test'
