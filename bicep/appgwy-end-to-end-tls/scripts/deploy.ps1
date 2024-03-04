$RG_NAME='appgwy-e2e-tls-pwsh-rg'
$LOCATION='australiaeast'
$SCRIPT_NAME='iis.ps1'
$CONTAINER_NAME='scripts'
$DOMAIN_NAME='kainiindustries.net'
$DNS_ZONE_RG_NAME='external-dns-zones-rg'
$CERT_FILE_PATH='../certs/api.kainiindustries.net.pfx'

# create file /scripts/env.json
# populate it with json representing the secret information

<#
{
    "ADMIN_USER_OBJECT_ID": "<your GUID>",
    "CERT_PASSWORD": "<your Password>",
    "VM_PASSWORD": "<your password>"
}
#>

if (Test-Path -Path ./certs/envv.json) {
    $vars = Get-Content -Path ./env.json | ConvertFrom-Json
} else {
    Write-Error -Exception "../cert/env.json not found"
    exit
}

# create .pfx from certificate & private key & add it to /certs directory
# openssl pkcs12 -export -out ../certs/api.kainiindustries.net.pfx -inkey ../certs/private.key -in ../certs/certificate.crt

az group create -g $RG_NAME -l $LOCATION

$STORAGE_ACCOUNT_INFO=$(az deployment group create `
    -g $RG_NAME `
    --template-file ../modules/storage.bicep `
    --name 'storage-deployment' `
    --parameters location=$LOCATION `
    --parameters containerName=$CONTAINER_NAME `
    --query "{CONTAINER_URI:properties.outputs.storageContainerUri.value, STORAGE_ACCOUNT_NAME:properties.outputs.storageAccountName.value}")

$STORAGE_CONTAINER_URI=$($STORAGE_ACCOUNT_INFO | ConvertFrom-Json).CONTAINER_URI
$STORAGE_ACCOUNT_NAME=$($STORAGE_ACCOUNT_INFO | ConvertFrom-Json).STORAGE_ACCOUNT_NAME

az storage blob upload --account-name $STORAGE_ACCOUNT_NAME --file ./$SCRIPT_NAME -c $CONTAINER_NAME -n $SCRIPT_NAME

$KEY_VAULT=$(az deployment group create `
    -g $RG_NAME `
    --template-file ../modules/keyvault.bicep `
    --name 'keyvault-deployment' `
    --parameters location=$LOCATION `
    --parameters adminObjectId=$($vars.ADMIN_USER_OBJECT_ID) `
    --query '{VAULT_NAME:properties.outputs.keyVaultName.value}')

$KEY_VAULT_NAME=$($KEY_VAULT | ConvertFrom-Json).VAULT_NAME

$CERT_INFO=$(az keyvault certificate import `
    --vault-name  $KEY_VAULT_NAME `
    -n ssl-cert `
    -f $CERT_FILE_PATH `
    --password $($vars.CERT_PASSWORD) `
    --query "{SID:sid, THUMBPRINT:x509ThumbprintHex}")

$CERT_SECRET_ID=$($CERT_INFO | ConvertFrom-Json).SID
$CERT_THUMBPRINT=$($CERT_INFO | ConvertFrom-Json).THUMBPRINT

az deployment group create `
    -g $RG_NAME `
    --template-file ../main.bicep `
    --name 'infra-deployment' `
    --parameters location=$LOCATION `
    --parameters domainName=$DOMAIN_NAME `
    --parameters storageAccountName=$STORAGE_ACCOUNT_NAME `
    --parameters storageContainerUri=$STORAGE_CONTAINER_URI `
    --parameters scriptName=$SCRIPT_NAME `
    --parameters backendPort=443 `
    --parameters frontendPort=443 `
    --parameters dnsZoneResourceGroup=$DNS_ZONE_RG_NAME `
    --parameters keyVaultName=$KEY_VAULT_NAME `
    --parameters frontEndHostName="api.$DOMAIN_NAME" `
    --parameters pfxCertSecretId=$CERT_SECRET_ID `
    --parameters pfxCertThumbprint=$CERT_THUMBPRINT `
    --parameters winVmPassword=$($vars.VM_PASSWORD)
