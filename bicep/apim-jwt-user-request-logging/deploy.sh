TENANT_ID='3d49be6f-6e38-404b-bbd4-f61c1a2d25bf'
RG_NAME='apim-jwt-app-insights-log-2-rg'
LOCATION='australiaeast'

az login --tenant $TENANT_ID

ACCESS_TOKEN=`az account get-access-token \
--query "accessToken" \
--output tsv`

echo "ACCESS_TOEN: $ACCESS_TOKEN"

az group create --name $RG_NAME --location $LOCATION

az deployment group create \
    --name apim-jwt-app-insights-log-deployment \
    --resource-group $RG_NAME \
    --template-file ./main.bicep \
    --parameters location=$LOCATION


API_URL=`az deployment group show \
    --name apim-jwt-app-insights-log-deployment \
    --resource-group $RG_NAME \
    --query "properties.outputs.apiUrl.value" \
    --output tsv`

# fails since no token is provided
curl $API_URL # { "statusCode": 401, "message": "sorry, validation has failed!" }

# succeeds
curl -H "Authorization: Bearer $ACCESS_TOKEN" $API_URL # { "test": "test response OK" }
