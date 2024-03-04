RG_NAME='app-svc-sql-svc-endpoint-rg'
LOCATION='australiaeast'
SQL_ADMIN_USER_NAME='dbadmin'
SQL_ADMIN_PASSWORD='P@ssword1234567890'
CONTAINER_NAME='nginx:latest'

# create resource group
az group create --name $RG_NAME --location $LOCATION

# deploy infrastructure
az deployment group create \
  --name appSvcDeployment \
  --resource-group $RG_NAME \
  --template-file ./main.bicep \
  --parameters location=$LOCATION \
  --parameters sqlAdminPassword=$SQL_ADMIN_PASSWORD \
  --parameters sqlAdminUserName=$SQL_ADMIN_USER_NAME \
  --parameters containerName=$CONTAINER_NAME \
  --verbose
