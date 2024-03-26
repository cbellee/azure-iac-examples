#!/bin/bash

location='australiaeast'
prefix='aks-workload-identity'
resourceGroup="$prefix-rg"
sshKeyPath='~/.ssh/id_rsa.pub' # this is also the secret wil will store & retrieve form key vault
k8sVersion='1.28.5'
fedIdCredName='kv-fed-id'
serviceAccountNamespace="default"
serviceAccountName="workload-identity-sa"

echo "Creating resource group..."
az group create -l "$location" -n "$resourceGroup"

echo "Deploying container registry..."
az deployment group create \
    --name 'acr-deployment' \
    --resource-group "$resourceGroup" \
    --template-file ./modules/acr.bicep \
    --parameters location="$location"

acrName=$(az deployment group show \
    --name 'acr-deployment' \
    --resource-group "$resourceGroup" \
    --query properties.outputs.acrName.value -o tsv)

echo "Building and pushing image..."
imageNameAndTag="$acrName.azurecr.io/kv-wi-server:latest"
az acr login -n $acrName
az acr build -t $imageNameAndTag -r $acrName .

echo "Deploying infrastructure..."
az deployment group create \
    --name 'infra-deployment' \
    --resource-group "$resourceGroup" \
    --template-file ./main.bicep \
    --parameters location="$location" \
    --parameters sshPublicKey=@"$sshKeyPath" \
    --parameters aksVersion="$k8sVersion" \
    --parameters acrName=$acrName

echo "Getting deployment outputs..."
aksClusterName=$(az deployment group show --name 'infra-deployment' --resource-group $resourceGroup --query properties.outputs.aksClusterName.value -o tsv)
wiUmidClientId=$(az deployment group show --name 'infra-deployment' --resource-group $resourceGroup --query properties.outputs.wiUmidClientId.value -o tsv)
wiUmidName=$(az deployment group show --name 'infra-deployment' --resource-group $resourceGroup --query properties.outputs.wiUmidName.value -o tsv)
oidcIssuerUrl=$(az deployment group show --name 'infra-deployment' --resource-group $resourceGroup --query properties.outputs.oidcIssuerUrl.value -o tsv)
export SECRET_NAME=$(az deployment group show --name 'infra-deployment' --resource-group $resourceGroup --query properties.outputs.secretName.value -o tsv)
export KEYVAULT_URL=$(az deployment group show --name 'infra-deployment' --resource-group $resourceGroup --query properties.outputs.keyVaultUrl.value -o tsv)

echo "Getting AKS credentials..."
az aks get-credentials \
    --resource-group $resourceGroup \
    --name $aksClusterName \
    --context aks-workload-identity \
    --overwrite-existing

echo "Creating Identity federation..."
az identity federated-credential create \
    --name $fedIdCredName \
    --identity-name $wiUmidName \
    --resource-group $resourceGroup \
    --issuer $oidcIssuerUrl \
    --subject "system:serviceaccount:$serviceAccountNamespace:$serviceAccountName"

# create service account
echo "Deploying service account and pod..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: $wiUmidClientId
  name: $serviceAccountName
  namespace: $serviceAccountNamespace
EOF

# create pod
cat <<EOF | kubectl apply -f -
kind: Pod
apiVersion: v1
metadata:
  name: kv-wi-server
  namespace: $serviceAccountNamespace
  labels:
    app: kv-wi-server
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: $serviceAccountName
  containers:
    - name: kv-wi-server
      image: $imageNameAndTag
      env:
      - name: KEYVAULT_URL
        value: ${KEYVAULT_URL}
      - name: SECRET_NAME
        value: ${SECRET_NAME}
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
        limits:
          cpu: 250m
          memory: 256Mi
      imagePullPolicy: Always
      ports:
        - containerPort: 8080
          protocol: TCP
EOF
