RESOURCE_GROUP="aca-background-processor-rg"
LOCATION="australiaeast"
STORAGE_ACCOUNT_NAME="stgcga76blpceaug"

az group create --name $RESOURCE_GROUP --location $LOCATION

az deployment group create -n 'infra-deployment' -g $RESOURCE_GROUP --template-file ./deploy.bicep  

QUEUE_CONNECTION_STRING=`az storage account show-connection-string -g $RESOURCE_GROUP --name $STORAGE_ACCOUNT_NAME --query connectionString --out json | tr -d '"'` 
az storage message put --content "Hello Queue Reader App" --queue-name "myqueue" --connection-string $QUEUE_CONNECTION_STRING
