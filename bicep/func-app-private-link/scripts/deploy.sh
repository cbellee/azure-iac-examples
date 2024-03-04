LOCATION='australiaeast'
RG_NAME="func-app-plink-$LOCATION-rg"

# create /.env file (in the project root folder) & add the line below.
# VM_ADMIN_PASSWORD='<vm password>'

. ../.env 

# create the resource group
az group create --name $RG_NAME --location $LOCATION

# deploy the environment
az deployment group create \
    --name "func-app-plink-$LOCATION-deployment" \
    --resource-group $RG_NAME \
    --mode Incremental \
    --parameters location=$LOCATION \
    --parameters ../main.parameters.json \
    --parameters vmAdminPassword=$VM_ADMIN_PASSWORD \
    --template-file ../main.bicep
