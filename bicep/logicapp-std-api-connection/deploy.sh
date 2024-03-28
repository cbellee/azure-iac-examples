location='australiaeast'
rgName='dec-logicapp-rg'
subscription=$(az account show --query id --output tsv)

# create resource group
az group create --location $location --name $rgName

# deploy 'existing' resources
az deployment group create \
    --name 'existing-deployment' \
    --resource-group $rgName \
    --template-file ./existing.bicep \
    --parameters addressPrefix='10.0.0.0/16' \
    --parameters location=$location

# get deployment output
outputs=$(az deployment group show \
    --name 'existing-deployment' \
    --resource-group $rgName \
    --query 'properties.outputs' \
    --output json)

aspname=$(echo $outputs | jq '.appServicePlanName.value' -r)
cosmosAccountName=$(echo $outputs | jq '.cosmosAccountName.value' -r)
storageAccount1Name=$(echo $outputs | jq '.storageAccount1Name.value' -r)
storageAccount2Name=$(echo $outputs | jq '.storageAccount2Name.value' -r)
storageAccount1QueueName=$(echo $outputs | jq '.storageAccount1QueueName.value' -r)
storageAccount2QueueName=$(echo $outputs | jq '.storageAccount2QueueName.value' -r)
vnetName=$(echo $outputs | jq '.vnetName.value' -r)
subnetName=$(echo $outputs | jq '.subnetName.value' -r)
keyVaultName=$(echo $outputs | jq '.keyVaultName.value' -r)
aiName=$(echo $outputs | jq '.aiName.value' -r)
uamiName=$(echo $outputs | jq '.uamiName.value' -r)

# deploy 'main' resources
az deployment group create \
    --name 'main-deployment' \
    --resource-group $rgName \
    --template-file ./deploy.bicep \
    --parameters location=$location \
    --parameters virtualNetworkName=$vnetName \
    --parameters subnetName=$subnetName \
    --parameters appServicePlanName=$aspname \
    --parameters storageAccount1Name=$storageAccount1Name \
    --parameters storageAccount2Name=$storageAccount2Name \
    --parameters aiName=$aiName \
    --parameters uamiName=$uamiName \
    --parameters queueName=$storageAccount2QueueName

# get deployment output
outputs=$(az deployment group show \
    --name 'main-deployment' \
    --resource-group $rgName \
    --query 'properties.outputs' \
    --output json)

logicAppName=$(echo $outputs | jq '.logicAppName.value' -r)

# zip workflow files
cd ./project
zip ./workflow.zip ./*
cd ..

# deploy workflow to logic app
az logicapp deployment source config-zip -g $rgName -n $logicAppName --subscription $subscription --src ./project/workflow.zip
