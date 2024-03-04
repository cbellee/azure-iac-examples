resourceGroupName='aks-agic-aks-rg'
location='australiaeast'

az group create -n $resourceGroupName -l $location

az deployment group create \
	--resource-group $resourceGroupName \
	--template-file ./main.bicep \
	--mode Incremental \
	--parameters ./main.parameters.json \
	--what-if-result-format FullResourcePayloads
