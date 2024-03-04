# vars
HUB_RG_NAME='test-hub-rg'
SPOKE_RG_NAME='test-spoke-rg'
LOCATION='australiaeast'
MYSQL_ADMIN_USER_NAME='dbadmin'
MYSQL_ADMIN_PASSWORD='M1cr0soft1234567890'
CONTAINER_IMAGE_NAME='go-web-api:v1.0'
MY_EXTERNAL_IP=$(dig +short myip.opendns.com @resolver1.opendns.com)

# hub deployment
az group create --name $HUB_RG_NAME --location $LOCATION

OUTPUT=$(az deployment group create \
  --name HubDeployment \
	--template-file ./hub.bicep \
	--resource-group $HUB_RG_NAME \
  --parameters myExternalIp=$MY_EXTERNAL_IP \
  --query '{acrLoginServer:properties.outputs.acrLoginServer.value, acrPassword:properties.outputs.acrPassword.value, acrName:properties.outputs.acrName.value, hubVnetId:properties.outputs.vnetId.value, hubVnetName:properties.outputs.vnetName.value}')

HUB_VNET_ID=$(echo $OUTPUT | jq '.vnetId' -r)
HUB_VNET_NAME=$(echo $OUTPUT | jq '.vnetName' -r)
ACR_NAME=$(echo $OUTPUT | jq '.acrName' -r)
ACR_LOGIN_SERVER=$(echo $OUTPUT | jq '.acrLoginServer' -r)
ACR_PASSWORD=$(echo $OUTPUT | jq '.acrPassword' -r)

#HUB_VNET_ID=$(az deployment group show \
#  --name HubDeployment \
#  --resource-group $HUB_RG_NAME \
#  --query properties.outputs.vnetId.value -o tsv)

#HUB_VNET_NAME=$(az deployment group show \
#  --name HubDeployment \
#  --resource-group $HUB_RG_NAME \
#  --query properties.outputs.vnetName.value -o tsv)

# push container image to private registry
docker login --password $ACR_PASSWORD --username $ACR_NAME $ACR_LOGIN_SERVER
docker tag "belstarr/$CONTAINER_IMAGE_NAME" $ACR_LOGIN_SERVER/$CONTAINER_IMAGE_NAME
docker push $ACR_LOGIN_SERVER/go-web-api:v1.0

# spoke deployment
az group create --name $SPOKE_RG_NAME --location $LOCATION

az deployment group create \
	--name SpokeDeployment \
	--template-file ./spoke.bicep \
	--resource-group $SPOKE_RG_NAME \
	--parameters mySqlAdminUserName=$MYSQL_ADMIN_USER_NAME \
	--parameters mySqlAdminPassword=$MYSQL_ADMIN_PASSWORD \
	--parameters hubVnetId=$HUB_VNET_ID \
	--parameters hubVnetName=$HUB_VNET_NAME \
	--parameters hubVnetResourceGroup=$HUB_RG_NAME \
	--parameters containerName="$ACR_NAME/$CONTAINER_IMAGE_NAME" \
  --parameters dockerRegistryUrl="https://$ACR_LOGIN_SERVER" \
  --parameters acrUserName=$ACR_NAME \
  --parameters acrPassword=$ACR_PASSWORD

WEB_APP_HOST_NAME=$(az deployment group show \
  --name SpokeDeployment \
  --resource-group $SPOKE_RG_NAME \
  --query properties.outputs.webAppHostName.value -o tsv)

WEB_APP_NAME=$(az deployment group show \
  --name SpokeDeployment \
  --resource-group $SPOKE_RG_NAME \
  --query properties.outputs.webAppName.value -o tsv)

# front door deployment
az deployment group create \
  --name FrontDoorDeployment \
  --template-file ./frontDoor.bicep \
  --resource-group $HUB_RG_NAME \
  --parameters backendAddress=$WEB_APP_HOST_NAME

FRONT_DOOR_ID=$(az deployment group show \
  --name FrontDoorDeployment \
  --resource-group $HUB_RG_NAME \
  --query properties.outputs.frontDoorId.value -o tsv)

# patch front door unique id to web app access-restriction
az webapp config access-restriction add \
	--resource-group $SPOKE_RG_NAME \
	--name $WEB_APP_NAME \
	--priority 400 \
	--service-tag AzureFrontDoor.Backend \
	--http-header x-azure-fdid=$FRONT_DOOR_ID
	