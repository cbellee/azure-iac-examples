ENVIRONMENT='staging'
LOCATION='australiaeast'
SUBSCRIPTION_ID=`az account show --query id -o tsv`
RG_NAME="aks-xplane-$ENVIRONMENT-rg"
SUBSCRIPTION_ID=`az account show --query id -o tsv`
GIT_REPO_URL='https://github.com/cbellee/azure-iac-examples'
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
ADMIN_GROUP_OBJECT_ID="f6a900e2-df11-43e7-ba3e-22be99d3cede"
LATEST_K8S_VERSION=$(az aks get-versions -l $LOCATION | jq -r -c '[.orchestrators[] | .orchestratorVersion][-1]')
UAMI='aks-csi-uami'

export SERVICE_ACCOUNT_NAME="workload-identity-sa"  # sample name; can be changed
export SERVICE_ACCOUNT_NAMESPACE="default" # can be changed to namespace of your workload
export FEDERATED_IDENTITY_NAME="aksfederatedidentity" # can be changed as needed

az group create --location $LOCATION --name $RG_NAME

az deployment group create \
    --resource-group $RG_NAME \
    --name aks-deployment \
    --template-file ./main.bicep \
    --parameters @main.parameters.json \
    --parameters environment=$ENVIRONMENT \
    --parameters gitRepoUrl=$GIT_REPO_URL \
    --parameters sshPublicKey="$SSH_KEY" \
    --parameters adminGroupObjectID=$ADMIN_GROUP_OBJECT_ID \
    --parameters aksVersion=$LATEST_K8S_VERSION \
    --parameters deployFluxConfig='false'

# KEYVAULT_NAME='az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.keyVaultName.value' -o tsv'
# KEYVAULT_ID='az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.keyVaultId.value' -o tsv'

CLUSTER_NAME=`az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.aksClusterName.value' -o tsv`
az aks get-credentials --resource-group $RG_NAME --name $CLUSTER_NAME --admin

# export UAMI_CLIENT_ID=`az identity create --name $UAMI --resource-group $RG_NAME --query 'clientId' -o tsv`
# export IDENTITY_TENANT=`az aks show --name $CLUSTER_NAME --resource-group $RG_NAME --query identity.tenantId -o tsv`
# AKS_OIDC_ISSUER=`az aks show --resource-group $RG_NAME --name $CLUSTER_NAME --query "oidcIssuerProfile.issuerUrl" -o tsv`

#az role assignment create \
#--role 'Key Vault Reader' \
#--assignee $UAMI_CLIENT_ID \
#--scope $KEYVAULT_ID

':
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: ${UAMI_CLIENT_ID}
  labels:
    azure.workload.identity/use: "true"
  name: ${SERVICE_ACCOUNT_NAME}
  namespace: ${SERVICE_ACCOUNT_NAMESPACE}
EOF

az identity federated-credential create \
--name $FEDERATED_IDENTITY_NAME \
--identity-name $UAMI \
--resource-group $RG_NAME \
--issuer "$AKS_OIDC_ISSUER" \
--subject "system:serviceaccount:$SERVICE_ACCOUNT_NAMESPACE:$SERVICE_ACCOUNT_NAME"

cat <<EOF | kubectl apply -f -
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-kv-crossplane-workload-identity # needs to be unique per namespace
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "false"          
    clientID: "${USER_ASSIGNED_CLIENT_ID}" # Setting this to use workload identity
    keyvaultName: ${KEYVAULT_NAME}       # Set to the name of your key vault
    cloudName: "AzurePublicCloud"        # [OPTIONAL for Azure] if not provided, the Azure environment defaults to AzurePublicCloud
    objects:  |
      array:
        - |
          objectName: crossplane
          objectType: secret              # object types: secret, key, or cert
          objectVersion: ""               # [OPTIONAL] object versions, default to latest if empty
    tenantId: "${IDENTITY_TENANT}"        # The tenant ID of the key vault
    secretObjects:
    - data:
      - key: crossplane-creds
        objectName: crossplane
      secretName: crossplane-creds
      type: Opaque
EOF
'