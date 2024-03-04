RG_NAME='aca-func-go-rg'
LOCATION='australiaeast'
ENVIRONMENT=dev
SEMVER=0.1.0
TAG="$ENVIRONMENT-$SEMVER"
IMAGE="func-api:$TAG"
ACR_TOKEN_NAME='acrPullToken'
ACR_TOKEN_EXPIRY_IN_DAYS=14

# create resource group
az group create --name $RG_NAME --location $LOCATION

# deploy Azure Container Registry
az deployment group create \
--resource-group $RG_NAME \
--name 'acr-deployment' \
--template-file ../infra/modules/acr.bicep \
--parameters location=$LOCATION

ACR_NAME=$(az deployment group show --resource-group $RG_NAME --name 'acr-deployment' --query properties.outputs.acrName.value -o tsv)

# create ACR Token
az acr token create -n $ACR_TOKEN_NAME -r $ACR_NAME --scope-map _repositories_pull --status enabled -onone

# generate password for ACR token
ACR_TOKEN_PASSWORD=$(az acr token credential generate -n $ACR_TOKEN_NAME -r $ACR_NAME --expiration-in-days $ACR_TOKEN_EXPIRY_IN_DAYS --password1 --query "passwords[0].value" -otsv)

# build image in ACR
az acr build -r $ACR_NAME -t $IMAGE -f ../func/Dockerfile ../func

# deploy ACA environment & function container app
az deployment group create \
--resource-group $RG_NAME \
--name 'aca-deployment' \
--template-file ../infra/main.bicep \
--parameters location=$LOCATION \
--parameters imageName="$ACR_NAME.azurecr.io/$IMAGE" \
--parameters acrTokenName=$ACR_TOKEN_NAME \
--parameters acrTokenPassword="$ACR_TOKEN_PASSWORD" \
--parameters funcName='todofunc' \
--parameters funcPort='80' \
--parameters acrName=$ACR_NAME
	