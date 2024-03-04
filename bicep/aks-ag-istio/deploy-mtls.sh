#!/bin/bash

while getopts "c" option; do
   case $option in
      c) certGen=1;; # use '-c' cmdline flag to generate certificates
      *) echo "usage: $0 [-s]" >&2
            exit 1 ;;
   esac
done

location='australiaeast'
prefix='aks-agw-istio'
resourceGroup="$prefix-rg"
istioIngressNamespace='aks-istio-ingress'
istioGatewayARecord='istiogwy'
currentUserObjectId=$(az ad signed-in-user show | jq .id -r)
sshKeyPath='~/.ssh/id_rsa.pub'
k8sVersion='1.27.3'
dnsZoneName='bellee.net'
internalDnsZone='internal.bellee.net'
publicHostName='gateway'
dnsResourceGroupName='external-dns-zones-rg'
export workloadIdentityServiceAccountName="workload-identity-sa"
export workloadIdentityServiceAccountNamespace="default"
export identityTenant=$(az account show --query tenantId -o tsv)
imageNameAndTag=go-mtls-server:v0.0.1

echo "sourcing 'pfxPassword' & 'publicCertificatePath' environment variables"
source ./.env

if [[ "$certGen" -eq '1' ]]; then
    echo "Generating root certificate..."
    openssl req -new \
        -x509 \
        -nodes \
        -days 365 \
        -subj '/CN=my-ca' \
        -keyout ./certs/ca.key \
        -out ./certs/ca.crt

    echo "Generating server certificate..."
    openssl genrsa -out ./certs/server.key

    openssl req -new \
        -key ./certs/server.key \
        -subj "/C=AU/CN=$internalDnsZone" \
        -addext "subjectAltName = DNS:$internalDnsZone" \
        -out ./certs/server.csr

    openssl x509 -req \
        -in ./certs/server.csr \
        -CA ./certs/ca.crt \
        -CAkey ./certs/ca.key \
        -CAcreateserial \
        -days 365 \
        -out ./certs/server.crt

    echo "Generating client certificate"
    openssl genrsa -out ./certs/client.key

    openssl req -new \
        -subj "/C=AU/CN=client" \
        -key ./certs/client.key \
        -out ./certs/client.csr

    openssl x509 -req \
        -in ./certs/client.csr \
        -CA ./certs/ca.crt \
        -CAkey ./certs/ca.key \
        -CAcreateserial \
        -out ./certs/client.crt \
        -days 365 \
        -sha256

    echo "Creating base64 encoded version of the root certificate..."
    cat ./certs/ca.crt | base64 -w 0 > ./certs/ca.crt.base64

    echo "Creating base64 encoded version of the client certificate..."
    cat ./certs/client.crt | base64 -w 0 > ./certs/client.crt.base64

    echo "Creating PFX version of the public certificate..."
    openssl pkcs12 -export \
        -out "$publicCertificatePath/star_bellee_net.pfx" \
        -inkey "$publicCertificatePath/bellee.net.key" \
        -in "$publicCertificatePath/star_bellee_net.crt" \
        -certfile "$publicCertificatePath/DigiCertCA.crt" \
        -certfile "$publicCertificatePath/TrustedRoot.crt" \
        -passout pass:$pfxPassword

    echo "creating PFX version of private certificate..."
    openssl pkcs12 -export \
        -in ./certs/server.crt \
        -inkey ./certs/server.key \
        -out ./certs/server.pfx \
        -passout pass:$pfxPassword

    echo "Displaying root certificate..."
    openssl x509 -in ./certs/ca.crt -text -noout

    echo "Displaying server certificate..."
    openssl x509 -in ./certs/server.crt -text -noout

    echo "Displaying client certificate..."
    openssl x509 -in ./certs/client.crt -text -noout

    echo "Displaying public certificate..."
    openssl x509 -in $publicCertificatePath/star_bellee_net.crt -text -noout

else
    echo "Skipping certificate generation..."
fi

echo "Creating resource group..."
az group create -l "$location" -n "$resourceGroup"

echo "Deploying key vault & UMID..."
az deployment group create \
    --name 'kv-deployment' \
    --resource-group "$resourceGroup" \
    --template-file ./modules/keyVault.bicep \
    --parameters location="$location" \
    --parameters umidName='gwy-umid' \
    --parameters userPrincipalId="$currentUserObjectId" \
    --parameters rootCertificateData=@./certs/ca.crt.base64

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

echo "Pushing image to ACR..."
az acr build \
    --registry "$acrName" \
    --image "$acrName.azurecr.io/$imageNameAndTag" \
    --file ./Dockerfile ./server

export keyVaultName=$(az deployment group show \
    --name 'kv-deployment' \
    --resource-group "$resourceGroup" \
    --query properties.outputs.keyVaultName.value -o tsv)

publicCertSecretId=$(az keyvault certificate import \
    --name 'public-cert' \
    --vault $keyVaultName \
    --file "$publicCertificatePath/star_bellee_net.pfx" \
    --password "$pfxPassword" \
    --query sid \
    -o tsv)

az keyvault certificate import \
    --name 'server-cert' \
    --vault $keyVaultName \
    --file "./certs/server.pfx" \
    --password "$pfxPassword"

az keyvault secret set \
    --name 'ca-cert' \
    --vault-name $keyVaultName \
    --file "./certs/ca.crt"

umidName=$(az deployment group show \
    --name 'kv-deployment' \
    --resource-group "$resourceGroup" \
    --query properties.outputs.umidName.value -o tsv)

rootCertSecretId=$(az deployment group show \
    --name 'kv-deployment' \
    --resource-group "$resourceGroup" \
    --query properties.outputs.rootCertificateSecretId.value -o tsv)

echo "Deploying infrastructure..."
az deployment group create \
    --name 'infra-deployment' \
    --resource-group "$resourceGroup" \
    --template-file ./main.bicep \
    --parameters location="$location" \
    --parameters umidName="$umidName" \
    --parameters rootCertSecretId="$rootCertSecretId" \
    --parameters publicCertSecretId="$publicCertSecretId" \
    --parameters istioGatewayARecordName="$istioGatewayARecord" \
    --parameters sshPublicKey=@"$sshKeyPath" \
    --parameters aksVersion="$k8sVersion" \
    --parameters rootCACertData=@./certs/ca.crt.base64 \
    --parameters publicHostName=$publicHostName \
    --parameters dnsZoneName=$dnsZoneName \
    --parameters dnsResourceGroupName=$dnsResourceGroupName \
    --parameters privateDnsZoneName=$internalDnsZone \
    --parameters acrName=$acrName \
    --parameters keyVaultName=$keyVaultName

echo "Getting deployment outputs..."
cluster=$(az deployment group show --name 'infra-deployment' --resource-group "$resourceGroup" --query properties.outputs.aksClusterName.value -o tsv)
appGatewayPublicIpAddress=$(az deployment group show --name 'infra-deployment' --resource-group "$resourceGroup" --query properties.outputs.appGatewayPublicIpAddress.value -o tsv)
appGatewayName=$(az deployment group show --name 'infra-deployment' --resource-group "$resourceGroup" --query properties.outputs.appGatewayName.value -o tsv)
export workloadIdentityClientId=$(az deployment group show --name 'infra-deployment' --resource-group "$resourceGroup" --query properties.outputs.workloadIdentityClientId.value -o tsv)
export workloadManagedIdentityName=$(az deployment group show --name 'infra-deployment' --resource-group "$resourceGroup" --query properties.outputs.workloadManagedIdentityName.value -o tsv)
export workloadManagedIdentityId=$(az deployment group show --name 'infra-deployment' --resource-group "$resourceGroup" --query properties.outputs.workloadManagedIdentityId.value -o tsv)
export oidcIssuerUrl=$(az deployment group show --name 'infra-deployment' --resource-group "$resourceGroup" --query properties.outputs.oidcIssuerUrl.value -o tsv)
export federatedIdentityName="aks-workload-federated-identity"

echo "Getting AKS credentials..."
az aks get-credentials --resource-group "$resourceGroup" --name "$cluster" --overwrite-existing

sed "s|<workloadIdentityClientId>|$workloadIdentityClientId|g;s|<workloadIdentityServiceAccountName>|$workloadIdentityServiceAccountName|g;" ./manifests/service_account.yaml | \
kubectl apply -n $workloadIdentityServiceAccountNamespace -f -

az identity federated-credential create --name $federatedIdentityName \
    --identity-name $workloadManagedIdentityName \
    --resource-group $resourceGroup \
    --issuer $oidcIssuerUrl \
    --subject system:serviceaccount:$workloadIdentityServiceAccountNamespace:$workloadIdentityServiceAccountName

# replace tokens & apply CSI key vault
sed "s|<workloadIdentityClientId>|$workloadIdentityClientId|g;s|<keyVaultName>|$keyVaultName|g;s|<identityTenant>|$identityTenant|g;" ./manifests/csi_secret_provider_class.yaml | kubectl apply -f -

# apply go-mtls pod
sed "s|<imageNameAndTag>|$acrName.azurecr.io/$imageNameAndTag|g;s|<serviceAccountName>|$workloadIdentityServiceAccountName|g;" ./manifests/go_mtls.yaml | kubectl apply -f -

echo "Enabling istio sidecar injection for the 'default' namespace..."
kubectl label namespace default istio.io/rev=asm-1-17

echo "Creating TLS certificate secret..."
kubectl delete secret tls-cert -n "$istioIngressNamespace"
kubectl create secret tls tls-cert --cert=./certs/server.crt --key=./certs/server.key -n "$istioIngressNamespace"

echo "Creating mTLS certificate secret..."
kubectl delete secret mtls-cert -n "$istioIngressNamespace"
kubectl create secret generic mtls-cert \
  --from-file=tls.key=./certs/server.key \
  --from-file=tls.crt=./certs/server.crt \
  --from-file=ca.crt=./certs/ca.crt \
  -n "$istioIngressNamespace" 

echo "Applying application manifests..."
kubectl apply -f ./manifests/bookinfo.yaml #https://raw.githubusercontent.com/istio/istio/release-1.17/samples/bookinfo/platform/kube/bookinfo.yaml

echo "Applying gateway & virtual service..."
kubectl apply -f ./manifests/gateway.yaml

while [[ "$result" != 'Healthy' ]]; do
    echo "Waiting for application gateway backend to be healthy..."
    result=$(az network application-gateway show-backend-health -g $resourceGroup  -n $appGatewayName --query backendAddressPools[0].backendHttpSettingsCollection[0].servers[0].health -o tsv)
    sleep 10
done

echo "Testing e2e gateway connectivity..."
curl --key ./certs/client.key \
    --cert ./certs/client.crt \
    --cacert "$publicCertificatePath/DigiCertRootCA_bundle.cer" \
    "https://bookinfo.$dnsZoneName/productpage" -v

curl --key ./certs/client.key \
    --cert ./certs/client.crt \
    --cacert "$publicCertificatePath/DigiCertRootCA_bundle.cer" \
    "https://bookinfo.$dnsZoneName/logout" -v

curl --key ./certs/client.key \
    --cert ./certs/client.crt \
    --cacert "$publicCertificatePath/DigiCertRootCA_bundle.cer" \
    "https://bookinfo.$dnsZoneName/api/v1/products" -v

curl --key ./certs/client.key \
    --cert ./certs/client.crt \
    --cacert "$publicCertificatePath/DigiCertRootCA_bundle.cer" \
    "https://bookinfo.$dnsZoneName/healthz/ready" -v # Istio health probe should return 404


curl https://go-mtls.bellee.net/hello \
    -H "X-Custom-Header-1: hello" \
    -H "X-Custom-Header-2: world" \
    --cacert ./certs/ca.crt \
    --cert ./certs/client.crt \
    --key ./certs/client.key \
    -vk

curl https://bookinfo.bellee.net/productpage \
    -H "X-Custom-Header-1: hello" \
    -H "X-Custom-Header-2: world" \
    --cacert ./certs/ca.crt \
    --cert ./certs/client.crt \
    --key ./certs/client.key \
    -vk
