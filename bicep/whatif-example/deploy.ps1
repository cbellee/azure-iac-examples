$RG_NAME='bicep-whatif-rg'

az group create --name $RG_NAME --location australiaeast

# deploy vnet
az deployment group create --resource-group $RG_NAME --template-file ./deploy.bicep

# deploy vnet change 
az deployment group what-if --resource-group $RG_NAME --template-file ./deploy_changes.bicep

$results = $(az deployment group what-if --resource-group $RG_NAME --template-file "deploy_changes.bicep" --no-pretty-print) | Convertfrom-Json

$results.changes.changeType
$results.changes.delta