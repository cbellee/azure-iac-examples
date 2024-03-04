#!/bin/bash

location='australiaeast'
prefix='aks-istio'
resourceGroup="$prefix-rg"
sshKeyPath='~/.ssh/id_rsa.pub'
k8sVersion='1.27.3'

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
cluster=$(az deployment group show --name 'infra-deployment' --resource-group "$resourceGroup" --query properties.outputs.aksClusterName.value -o tsv)

echo "Getting AKS credentials..."
az aks get-credentials --resource-group "$resourceGroup" --name "cluster-ytuypx4ecpydm" --context aks-istio --overwrite-existing

# deploy external Istio gateway
# az aks mesh enable-ingress-gateway --resource-group $resourceGroup --name $cluster --ingress-gateway-type external

echo "Enabling istio sidecar injection for the 'default' namespace..."
kubectl label namespace default istio.io/rev=asm-1-17

# deploy bookinfo app
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.17/samples/bookinfo/platform/kube/bookinfo.yaml

kubectl get svc,deployment,pods -o wide

kubectl describe pod -l app=productpage

# evvoy proxy log output
kubectl logs $(kubectl get pod -l app=productpage -o jsonpath="{.items[0].metadata.name}") istio-proxy

# deploy external gateway
kubectl apply -f ./bookinfo/networking/bookinfo-gateway.yaml -n default