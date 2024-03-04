location='australiaeast'
prefix='aks-private-azfw'
deploymentName='infra-deployment'
rgName="${prefix}-rg"
CLOUD_INIT_CONTENT=$(cat ./cloudinit.txt)

# create resource group
az group create -n $rgName -l $location

# start Bicep template deployment
az deployment group create \
    -g $rgName \
    -n $deploymentName \
    -f ../azuredeploy.bicep \
    -p ../azuredeploy.parameters.json \
    -p customData="$CLOUD_INIT_CONTENT"
