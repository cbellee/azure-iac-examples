RG_NAME='ag-apim-aks-australiaeast-2-rg'
ACR_NAME=$(az deployment group show --resource-group $RG_NAME --name 'ag-apim-aks-deploy' --query properties.outputs.acrName.value -o tsv)

ENVIRONMENT=dev
SEMVER=0.1.2
TAG="$ENVIRONMENT-$SEMVER"

SPA_IMAGE="spa:$TAG"

ORDER_API_IMAGE="order:$TAG"
ORDER_API_PORT="8080"

PRODUCT_API_IMAGE="product:$TAG"
PRODUCT_API_PORT="8081"

# build order image in ACR
az acr build -r $ACR_NAME \
    -t $ORDER_API_IMAGE \
    --build-arg SERVICE_PORT=$ORDER_API_PORT \
    -f ../src/Dockerfile ../src/order

# build product image in ACR
az acr build -r $ACR_NAME \
    -t $PRODUCT_API_IMAGE \
    --build-arg SERVICE_PORT=$PRODUCT_API_PORT \
    -f ../src/Dockerfile ../src/product

# build React SPA in ACR
az acr build -r $ACR_NAME \
    -t $SPA_IMAGE \
    -f ../src/spa/Dockerfile ../src/spa