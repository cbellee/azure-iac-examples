rgName='vmss-demo-1'
adminUsername='localadmin'
adminPassword='M1cr0soft123'
certPassword='M1cr0soft123'
location='australiaeast'
deploymentName='infra-deployment'
hostname='myapp.kainiindustries.net'
sshPublicKey=$(cat ~/.ssh/id_rsa.pub)
vmssInstanceCount=3
appGwyHostName='myapp.kainiindustries.net'
aRecordName='myapp' 
dnsZoneName='kainiindustries.net'
forceScriptUpdate=$(date +%N)
dnsResourceGroupName='external-dns-zones-rg'

:'
openssl ecparam -out root.key -name prime256v1 -genkey
openssl req -new -sha256 -key root.key -out root.csr -subj "/C=AU/ST=NSW/L=Sydney/O=IT/CN=kainiindustries.net"
openssl x509 -req -sha256 -days 365 -in root.csr -signkey root.key -out root.crt
openssl ecparam -out client.key -name prime256v1 -genkey
openssl req -new -sha256 -key client.key -out client.csr -subj "/C=AU/ST=NSW/L=Sydney/O=IT/CN=myapp.kainiindustries.net"
openssl x509 -req -in client.csr -CA root.crt -CAkey root.key -CAcreateserial -out client.crt -days 365 -sha256 
openssl x509 -in client.crt -text -noout
openssl pkcs12 -export -out client.pfx -inkey client.key -in client.crt
openssl base64 -in ./client.pfx -out ./clientbase64
'

cert=$(cat ../certs/clientbase64)

az group create --name $rgName --location $location

az deployment group create \
    --name storageDeployment \
    --resource-group $rgName \
    --template-file ./modules/storage.bicep \
    --parameters=sasTokenExpiry='2022-07-01T00:00:00Z'

CONTAINER_NAME=$(az deployment group show --name storageDeployment --resource-group $rgName --query 'properties.outputs.storageContainerName.value' -o tsv)
STORAGE_ACCOUNT_NAME=$(az deployment group show --name storageDeployment --resource-group $rgName --query 'properties.outputs.storageAccountName.value' -o tsv)
CONTAINER_URI=$(az deployment group show --name storageDeployment --resource-group $rgName --query 'properties.outputs.storageContainerUri.value' -o tsv)
SAS_TOKEN=$(az deployment group show --name storageDeployment --resource-group $rgName --query 'properties.outputs.storageAccountSasToken.value' -o tsv)

az storage azcopy blob upload --container $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --source "../app/main" --recursive
az storage azcopy blob upload --container $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --source "../scripts/install.sh" --recursive

az deployment group create \
    --name $deploymentName \
    --resource-group $rgName \
    --template-file ./main.bicep \
    --parameters adminUsername=$adminUsername \
    --parameters adminPassword=$adminPassword \
    --parameters pfxCert="$cert" \
    --parameters pfxCertPassword=$certPassword \
    --parameters appGwyHostName=$hostName \
    --parameters vmssInstanceCount=$vmssInstanceCount \
    --parameters vmssCustomScriptUri=$CONTAINER_URI \
    --parameters appGwyHostName=$appGwyHostName \
    --parameters sshPublicKey="$sshPublicKey" \
    --parameters dnsResourceGroupName=$dnsResourceGroupName \
    --parameters dnsZoneName=$dnsZoneName \
    --parameters dnsARecordName=$aRecordName \
    --parameters forceScriptUpdate=$forceScriptUpdate \
    --parameters storageAccountName=$STORAGE_ACCOUNT_NAME
