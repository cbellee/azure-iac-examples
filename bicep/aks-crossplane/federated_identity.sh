export subscriptionID=`az account show --query id -o tsv`
export resourceGroupName=<resource group name>
export UAMI=<name for user assigned identity>
export KEYVAULT_NAME=<existing keyvault name>
export clusterName=<aks cluster name>

az account set --subscription $subscriptionID
az identity create --name $UAMI --resource-group $resourceGroupName
export USER_ASSIGNED_CLIENT_ID="$(az identity show -g $resourceGroupName --name $UAMI --query 'clientId' -o tsv)"
export IDENTITY_TENANT=$(az aks show --name $clusterName --resource-group $resourceGroupName --query identity.tenantId -o tsv)

