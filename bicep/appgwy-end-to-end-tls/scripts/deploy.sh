RG_NAME='appgwy-e2e-tls-rg'
LOCATION='australiaeast'
IIS_SCRIPT_NAME='iis.ps1'
APACHE_SCRIPT_NAME='apache.sh'
CONTAINER_NAME='scripts'
DOMAIN_NAME='kainiindustries.net'
DNS_ZONE_RG_NAME='external-dns-zones-rg'
CERT_FILE_PATH='../certs/star.kainiindustries.net.bundle.pfx'
ADMIN_USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)
SSH_KEY="$(cat ~/.ssh/id_rsa.pub)"
INTERNAL_HOST_NAME="apache.internal.${DOMAIN_NAME}"
PRIVATE_KEY_FILE='../certs/key.pem'
PRIVATE_CERT_FILE='../certs/cert.crt'
PRIVATE_CERT_NAME=$(echo "apache.internal.${DOMAIN_NAME}") # | sed 's/\./-/') # replace any '.' chars with '-' 
PRIVATE_PFX_CERT_FILE="../certs/apache.internal.${DOMAIN_NAME}.pfx"
CLOUD_INIT_CONTENT=$(cat ./cloud-init.txt)

. ../.env

# generate root ca key
openssl genrsa -passout pass:$CERT_PASSWORD -des3 -out ../certs/ca.key 2048 
openssl req -new -passin pass:$CERT_PASSWORD -subj "/C=AU/ST=NSW/L=Sydney/O=KainiIndustries/OU=IT/CN=internal.kainiindustries.net" -sha256 -key ../certs/ca.key -out ../certs/ca.csr
openssl x509 -passin pass:$CERT_PASSWORD -req -sha256 -days 365 -in ../certs/ca.csr -signkey ../certs/ca.key -out ../certs/ca.crt
openssl genrsa -out ../certs/internal.kainiindustries.net.key

openssl req -new -subj "/C=AU/ST=NSW/L=Sydney/O=KainiIndustries/OU=IT/CN=apache.internal.kainiindustries.net" -sha256 -key ../certs/internal.kainiindustries.net.key -out ../certs/apache.internal.kainiindustries.net.csr
openssl x509 -passin pass:$CERT_PASSWORD -req -in ../certs/apache.internal.kainiindustries.net.csr -CA ../certs/ca.crt -CAkey ../certs/ca.key -CAcreateserial -out ../certs/apache.internal.kainiindustries.net.crt -days 365 -sha256

openssl req -new -subj "/C=AU/ST=NSW/L=Sydney/O=KainiIndustries/OU=IT/CN=iis.internal.kainiindustries.net" -sha256 -key ../certs/internal.kainiindustries.net.key -out ../certs/iis.internal.kainiindustries.net.csr
openssl x509 -passin pass:$CERT_PASSWORD -req -in ../certs/iis.internal.kainiindustries.net.csr -CA ../certs/ca.crt -CAkey ../certs/ca.key -CAcreateserial -out ../certs/iis.internal.kainiindustries.net.crt -days 365 -sha256

cp ../certs/ca.crt ../certs/ca.cer

# verify certificate
openssl x509 -in ../certs/myapp.internal.kainiindustries.net.crt -text -noout

# create PFX
openssl pkcs12 -password pass:$CERT_PASSWORD -export -out ../certs/iis.internal.kainiindustries.net.pfx -inkey ../certs/internal.kainiindustries.net.key -in ../certs/iis.internal.kainiindustries.net.crt
openssl pkcs12 -password pass:$CERT_PASSWORD -export -out ../certs/apache.internal.kainiindustries.net.pfx -inkey ../certs/internal.kainiindustries.net.key -in ../certs/apache.internal.kainiindustries.net.crt

# create .pem
cat ../certs/apache.internal.kainiindustries.net.crt ../certs/internal.kainiindustries.net.key > ../certs/internal.kainiindustries.net.pem

openssl pkcs12 -in ../certs/apache.internal.kainiindustries.net.pfx -out ../certs/apache.internal.kainiindustries.net.pem -nodes -password pass:$CERT_PASSWORD
openssl x509 -in ../certs/apache.internal.kainiindustries.net.pem >> ../certs/temp.pem
openssl pkcs8 -topk8 -nocrypt -in ../certs/apache.internal.kainiindustries.net.pem >> ../certs/temp.pem

az keyvault certificate create \
    --vault-name $KEY_VAULT_NAME \
    --name mycert \
    --policy "$(az keyvault certificate get-default-policy)"

secret=$(az keyvault secret list-versions \
          --vault-name $keyvault_name \
          --name mycert \
          --query "[?attributes.enabled].id" --output tsv)
vm_secret=$(az vm secret format --secrets "$secret" -g myResourceGroupSecureWeb --keyvault $keyvault_name)

':
# create self-signed TLS certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ${PRIVATE_KEY_FILE} \
  -out ${PRIVATE_CERT_FILE} \
  -subj "/CN=${INTERNAL_HOST_NAME}/O=${INTERNAL_HOST_NAME}" \
  -addext "subjectAltName = DNS:${INTERNAL_HOST_NAME}"

openssl req -new -x509 \
  -key ${PRIVATE_KEY_FILE} \
  -out ../certs/cacert.pem -days 1095 \
  -subj "/CN=${INTERNAL_HOST_NAME}/O=${INTERNAL_HOST_NAME}" \
  -addext "subjectAltName = DNS:${INTERNAL_HOST_NAME}"

# convert self-signed TLS certificate to PFX format
openssl pkcs12 -export -inkey $PRIVATE_KEY_FILE -in $PRIVATE_CERT_FILE -out $PRIVATE_PFX_CERT_FILE -password pass:$CERT_PASSWORD
'

az group create -g $RG_NAME -l $LOCATION

STORAGE_ACCOUNT_INFO=$(az deployment group create \
    -g $RG_NAME \
    --template-file ../modules/storage.bicep \
    --name 'storage-deployment' \
    --parameters location=$LOCATION \
    --parameters containerName=$CONTAINER_NAME \
    --query "{CONTAINER_URI:properties.outputs.storageContainerUri.value, STORAGE_ACCOUNT_NAME:properties.outputs.storageAccountName.value}")

STORAGE_CONTAINER_URI=$(echo $STORAGE_ACCOUNT_INFO | jq .CONTAINER_URI -r)
STORAGE_ACCOUNT_NAME=$(echo $STORAGE_ACCOUNT_INFO | jq .STORAGE_ACCOUNT_NAME -r)

az storage blob upload --account-name $STORAGE_ACCOUNT_NAME --file ./$IIS_SCRIPT_NAME -c $CONTAINER_NAME -n $IIS_SCRIPT_NAME
az storage blob upload --account-name $STORAGE_ACCOUNT_NAME --file ./$APACHE_SCRIPT_NAME -c $CONTAINER_NAME -n $APACHE_SCRIPT_NAME

KEY_VAULT_NAME=$(az deployment group create \
    -g $RG_NAME \
    --template-file ../modules/keyvault.bicep \
    --name 'keyvault-deployment' \
    --parameters location=$LOCATION \
    --parameters adminObjectId=$ADMIN_USER_OBJECT_ID \
    --query 'properties.outputs.keyVaultName.value' -o tsv)

TRUSTED_ROOT_CERT_ID=$(az keyvault secret set \
    --vault-name $KEY_VAULT_NAME \
    -n trusted-root-cert \
    -f ../certs/ca.cer \
    --query id -o tsv)

BACKEND_CERT_ID=$(az keyvault secret set \
    --vault-name $KEY_VAULT_NAME \
    -n backend-cert \
    -f ../certs/apache.internal.kainiindustries.net.crt \
    --query id -o tsv)

BACKEND_KEY_ID=$(az keyvault secret set \
    --vault-name $KEY_VAULT_NAME \
    -n backend-key \
    -f ../certs/apache.internal.kainiindustries.net.key \
    --query id -o tsv)

BACKEND_PFX_CERT_INFO=$(az keyvault certificate import \
    --vault-name $KEY_VAULT_NAME \
    -n backend-pfx-cert \
    --password $CERT_PASSWORD \
    -f ../certs/iis.internal.kainiindustries.net.pfx \
    --query "{SID:sid, THUMBPRINT:x509ThumbprintHex}")

BACKEND_PEM_CERT_INFO=$(az keyvault certificate import \
    --vault-name $KEY_VAULT_NAME \
    -n backend-pem-cert \
    --password $CERT_PASSWORD \
    -f ../certs/temp.pem \
    --query "{SID:sid, THUMBPRINT:x509ThumbprintHex}")

CERT_INFO=$(az keyvault certificate import \
    --vault-name $KEY_VAULT_NAME \
    -n ssl-cert \
    -f $CERT_FILE_PATH \
    --password $CERT_PASSWORD \
    --query "{SID:sid, THUMBPRINT:x509ThumbprintHex}")

PUBLIC_CERT_SECRET_ID=$(echo $CERT_INFO | jq .SID -r)
PUBLIC_CERT_THUMBPRINT=$(echo $CERT_INFO | jq .THUMBPRINT -r)

BACKEND_PFX_CERT_SECRET_ID=$(echo $BACKEND_PFX_CERT_INFO | jq .SID -r)
BACKEND_PFX_CERT_THUMBPRINT=$(echo $BACKEND_PFX_CERT_INFO | jq .THUMBPRINT -r)

BACKEND_PEM_CERT_SECRET_ID=$(echo $BACKEND_PEM_CERT_INFO | jq .SID -r)

az deployment group create \
    -g $RG_NAME \
    --template-file ../main.bicep \
    --name 'infra-deployment' \
    --parameters location=$LOCATION \
    --parameters domainName=$DOMAIN_NAME \
    --parameters storageAccountName=$STORAGE_ACCOUNT_NAME \
    --parameters storageContainerUri=$STORAGE_CONTAINER_URI \
    --parameters windowsScriptName=$IIS_SCRIPT_NAME \
    --parameters linuxScriptName=$APACHE_SCRIPT_NAME \
    --parameters windowsBackendHostName='iis.internal.kainiindustries.net' \
    --parameters linuxBackendHostName='apache.internal.kainiindustries.net' \
    --parameters backendPort=443 \
    --parameters frontendPort=443 \
    --parameters dnsZoneResourceGroup=$DNS_ZONE_RG_NAME \
    --parameters keyVaultName=$KEY_VAULT_NAME \
    --parameters frontEndHostName="web.$DOMAIN_NAME" \
    --parameters publicPfxCertId=$PUBLIC_CERT_SECRET_ID \
    --parameters backendPfxThumbprint=$BACKEND_PFX_CERT_THUMBPRINT \
    --parameters trustedRootCertId=$TRUSTED_ROOT_CERT_ID \
    --parameters backendPemCertId=$BACKEND_PEM_CERT_SECRET_ID \
    --parameters backendPfxCertId=$BACKEND_PFX_CERT_SECRET_ID \
    --parameters winVmPassword=$VM_PASSWORD \
    --parameters customData="$CLOUD_INIT_CONTENT" \
    --parameters sshKey="$SSH_KEY"
