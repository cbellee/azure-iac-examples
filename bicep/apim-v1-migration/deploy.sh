location='australiaeast'
rgName='apim-v1-migration-rg'

az group create --location $location --name $rgName
az deployment group create --name 'my-deployment' -g $rgName --template-file ./apim_stv1.bicep --parameters location=$location