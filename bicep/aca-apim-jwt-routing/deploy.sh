#### NOTE #################
# replace '<your_first_tenant_id>' & '<your_second_tenant_id>' placeholders with the Azure EntraID tenant GUIDs
# replace '<your_first_tenant_name>' with the name of your first tenant Id

location='australiaeast'
rgName="appgwy-apim-aca-jwt-routing-rg"
currentUser=$(az ad signed-in-user show --query id -o tsv)
tenantId=$(az account show --query homeTenantId -o tsv)
betaTenantName='<your_first_tenant_name>'

# create resource group
az group create --location $location --name $rgName

acrName=$(az deployment group create \
  --resource-group $rgName \
  --name 'acr-deployment' \
  --template-file ./modules/acr.bicep \
  --parameters location=$location \
  --query properties.outputs.name.value \
  --output tsv)

az acr login --name $acrName
az acr build -t "$acrName.azurecr.io/colourapp:latest" --registry $acrName .

# deploy infrastructure
az deployment group create \
    --resource-group $rgName \
    --name 'infra-deployment' \
    --template-file ./main.bicep \
    --parameters location=$location \
    --parameters acrName=$acrName \
    --parameters containerImageName="$acrName.azurecr.io/colourapp" \
    --parameters containerImageTag='latest' \
    --parameters version='0.1.0' \
    --parameters betaTenantName=$betaTenantName \
    --parameters validIssuers='<issuers><issuer>https://sts.windows.net/<your_first_tenant_id>/</issuer><issuer>https://sts.windows.net/<your_second_tenant_id>/</issuer></issuers>'

output=$(az deployment group show \
    --resource-group $rgName \
    --name 'infra-deployment' \
    --query 'properties.outputs')

appGwyIp=$(echo $output | jq '.appGwyIp.value' -r)

# test the policy

# get a valid token for one the current EntraID tenant
token=$(az account get-access-token --tenant ${tenantId} | jq .accessToken -r)
curl -H 'Accept: application/json' -H "Authorization: Bearer ${token}" http://${appGwyIp}/colourapp

# repeat again, but this time login to the other tenant in 'validIssuers'

# az login -t '<your_second_tenant_name>'
# token=$(az account get-access-token --tenant '<your_second_tenant_id>' | jq .accessToken -r)
# curl -H 'Accept: application/json' -H "Authorization: Bearer ${token}" http://${appGwyIp}/colourapp