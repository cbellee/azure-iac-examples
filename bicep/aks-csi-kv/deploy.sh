LOCATION='australiaeast'
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
export TENANT_ID=$(az account show --query tenantId -o tsv)
ADMIN_GROUP_OBJECT_ID="9a9ebfda-180c-4957-b9ce-2e2fbfbd2a0f"
SERVICE_ACCOUNT_NAMESPACE='demo'
SERVICE_ACCOUNT_NAME='busybox-wi-sa'
PREFIX=csidriver
export RG_NAME="aks-${PREFIX}-rg"
export SECRET_NAME='secret1'
export SECRET_VALUE='this is a secret'

az group create --location $LOCATION --name $RG_NAME

az deployment group create \
    --resource-group $RG_NAME \
    --name aks-deployment \
    --template-file ./main.bicep \
    --parameters @main.parameters.json \
    --parameters prefix=$PREFIX \
    --parameters sshPublicKey="$SSH_KEY" \
    --parameters adminGroupObjectID=$ADMIN_GROUP_OBJECT_ID \
    --parameters aksVersion='1.30.0' \
    --parameters secretName=$SECRET_NAME \
    --parameters secretValue=$SECRET_VALUE

export CLUSTER_NAME=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.aksClusterName.value' -o tsv)
export KV_ID=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.keyVaultId.value' -o tsv)
export KV_NAME=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query properties.outputs.keyVaultName.value -o tsv)
export KV_CSI_IDENTITY_CLIENT_ID=$(az aks show -g $RG_NAME -n $CLUSTER_NAME --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv)
export KV_CSI_IDENTITY_RESOURCE_ID=$(az aks show -g $RG_NAME -n $CLUSTER_NAME --query addonProfiles.azureKeyvaultSecretsProvider.identity.resourceId -o tsv)
export AKS_NODE_RG_NAME=$(az aks show -g $RG_NAME -n $CLUSTER_NAME --query nodeResourceGroup -o tsv)

# add kv admin role to csi identity
az role assignment create \
    --role 'Key Vault Administrator' \
    --assignee $KV_CSI_IDENTITY_CLIENT_ID \
    --scope $KV_ID

# get cluster credentials
az aks get-credentials -g $RG_NAME -n $CLUSTER_NAME --admin

# grant the runner of this script access to the key vault
az role assignment create \
    --role 'Key Vault Administrator' \
    --assignee $KV_CSI_IDENTITY_CLIENT_ID \
    --scope $KEYVAULT_SCOPE

# create secret provider class
kubectl create namespace $SERVICE_ACCOUNT_NAMESPACE

cat <<EOF | kubectl apply -n $SERVICE_ACCOUNT_NAMESPACE -f -
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-kvname-wi # needs to be unique per namespace
spec:
  provider: azure
  secretObjects:
  - data:
    - key: secretkey1
      objectName: ${SECRET_NAME}
    secretName: k8ssecret1
    type: Opaque
  parameters:
    usePodIdentity: "false"
    clientID: "${KV_CSI_IDENTITY_CLIENT_ID}" # Setting this to use workload identity
    keyvaultName: ${KV_NAME}       # Set to the name of your key vault
    cloudName: ""                         # [OPTIONAL for Azure] if not provided, the Azure environment defaults to AzurePublicCloud
    objects:  |
      array:
        - |
          objectName: ${SECRET_NAME}            # Set to the name of your secret
          objectType: secret              # object types: secret, key, or cert
          objectVersion: ""               # [OPTIONAL] object versions, default to latest if empty
    tenantId: "${TENANT_ID}"        # The tenant ID of the key vault
EOF

export KV_CSI_IDENTITY_RESOURCE_NAME=$(az identity show --ids $KV_CSI_IDENTITY_RESOURCE_ID --query name -o tsv)
export AKS_OIDC_ISSUER="$(az aks show -n $CLUSTER_NAME -g $RG_NAME --query "oidcIssuerProfile.issuerUrl" -o tsv)"

az identity federated-credential create --name 'kv-csi-identity-federation' \
  --identity-name $KV_CSI_IDENTITY_RESOURCE_NAME \
  --resource-group $AKS_NODE_RG_NAME \
  --issuer $AKS_OIDC_ISSUER \
  --subject "system:serviceaccount:$SERVICE_ACCOUNT_NAMESPACE:$SERVICE_ACCOUNT_NAME" \
  --audiences api://AzureADTokenExchange

cat <<EOF | kubectl apply -n $SERVICE_ACCOUNT_NAMESPACE -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: ${KV_CSI_IDENTITY_RESOURCE_ID}
  name: ${SERVICE_ACCOUNT_NAME}
  namespace: ${SERVICE_ACCOUNT_NAMESPACE}
EOF

# create pod & service
cat <<EOF | kubectl apply -n $SERVICE_ACCOUNT_NAMESPACE -f -
kind: Pod
apiVersion: v1
metadata:
  name: busybox-secrets-store-inline-wi
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: $SERVICE_ACCOUNT_NAME
  containers:
    - name: busybox
      image: registry.k8s.io/e2e-test-images/busybox:1.29-4
      command:
        - "/bin/sleep"
        - "10000"
      volumeMounts:
      - name: secrets-store01-inline
        mountPath: "/mnt/secrets-store"
        readOnly: true
      env:
      - name: MY_SECRET
        valueFrom:
          secretKeyRef:
            name: k8ssecret1
            key: secretkey1
  volumes:
    - name: secrets-store01-inline
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
          secretProviderClass: "azure-kvname-wi"
EOF

# exec inside pod
k exec -it -n demo busybox-secrets-store-inline-wi  -- sh
# read env var containing secret value
# echo $MY_SECRET