#!/bin/bash

LOCATION='australiaeast'
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
LATEST_K8S_VERSION=$(az aks get-versions -l $LOCATION | jq -r -c '[.orchestrators[] | .orchestratorVersion][-1]')
PREFIX='aks-appgw-private-nginx'
RG_NAME="$PREFIX-rg"
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)

PUBLIC_DNS_ZONE_RG_NAME='external-dns-zones-rg'
DOMAIN_NAME='kainiindustries.net'
INTERNAL_HOST_NAME="internal.nginx.${DOMAIN_NAME}"

PUBLIC_PFX_CERT_FILE="./certs/star.${DOMAIN_NAME}.bundle.pfx"
PUBLIC_PFX_CERT_NAME='public-certificate-pfx'

PRIVATE_KEY_FILE='./certs/key.pem'
PRIVATE_CERT_FILE='./certs/cert.crt'
ROOT_CERT_FILE='./certs/cert.cer'
ROOT_CERT_NAME='root-certificate'

PRIVATE_CERT_NAME=$(echo "internal-nginx-${DOMAIN_NAME}" | sed 's/\./-/') # replace any '.' chars with '-'
PRIVATE_PFX_CERT_FILE="./certs/internal-nginx-${DOMAIN_NAME}.pfx"

# grep IP from internal-ingress.yaml
INGRESS_PRIVATE_IP=$(cat ./manifests/internal-ingress.yaml | grep -oE "\b[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}") # get ILB IP address

NGINX_INGRESS_NAMESPACE='ingress-nginx'
NGINX_INGRESS_SERVICE='ingress-nginx'
NGINX_CLIENT_CERT_NAME='nginx-client-cert'
APP_NAMESPACE='httpbin'

source ./.env

# create self-signed TLS certificate to secure NGINX to App Gateway communication 
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ${PRIVATE_KEY_FILE} \
  -out ${PRIVATE_CERT_FILE} \
  -subj "/CN=${INTERNAL_HOST_NAME}/O=${INTERNAL_HOST_NAME}" \
  -addext "subjectAltName = DNS:${INTERNAL_HOST_NAME}"

# make a copy of the certificate, changing file extension to '.cer'
cp ${PRIVATE_CERT_FILE} ${ROOT_CERT_FILE}

# convert self-signed TLS certificate to PFX format
openssl pkcs12 -export -inkey $PRIVATE_KEY_FILE -in $PRIVATE_CERT_FILE -out $PRIVATE_PFX_CERT_FILE -password pass:$PRIVATE_CERT_PASSWORD

# create resource group
az group create --location $LOCATION --name $RG_NAME

# deploy key vault
az deployment group create \
  --resource-group $RG_NAME \
  --name kv-deployment \
  --template-file ./modules/keyvault.bicep \
  --parameters keyVaultAdminObjectId=$ADMIN_GROUP_OBJECT_ID \
  --parameters location=$LOCATION

KV_NAME=$(az deployment group show --resource-group $RG_NAME --name kv-deployment --query 'properties.outputs.keyVaultName.value' -o tsv)

# upload public tls certificate to Key Vault
PUBLIC_CERT_PROPS=$(az keyvault certificate import --vault-name $KV_NAME -n $PUBLIC_PFX_CERT_NAME -f $PUBLIC_PFX_CERT_FILE --password $PUBLIC_CERT_PASSWORD)
# PUBLIC_CERT_SID=$(echo $PUBLIC_CERT_PROPS | jq .sid -r)
PUBLIC_CERT_SID="https://$KV_NAME.vault.azure.net/certificates/$PUBLIC_PFX_CERT_NAME"

# upload backend trusted root tls certificate to Key Vault
ROOT_CERT_PROPS=$(az keyvault secret set --name $ROOT_CERT_NAME --vault-name $KV_NAME --file $ROOT_CERT_FILE --encoding base64)
# ROOT_CERT_SID=$(echo $ROOT_CERT_PROPS | jq .id -r)
ROOT_CERT_SID="https://$KV_NAME.vault.azure.net/secrets/$ROOT_CERT_NAME"

# deploy infrastructure
az deployment group create \
  --resource-group $RG_NAME \
  --name infra-deployment \
  --template-file ./main.bicep \
  --parameters @main.parameters.json \
  --parameters location=$LOCATION \
  --parameters sshPublicKey="$SSH_KEY" \
  --parameters adminGroupObjectID=$ADMIN_GROUP_OBJECT_ID \
  --parameters k8sVersion=$LATEST_K8S_VERSION \
  --parameters dnsPrefix=$PREFIX \
  --parameters nginxBackendIpAddress=$INGRESS_PRIVATE_IP \
  --parameters nginxTlsCertSecretId=$ROOT_CERT_SID \
  --parameters tlsCertSecretId=$PUBLIC_CERT_SID \
  --parameters keyVaultName=$KV_NAME \
  --parameters publicDnsZoneName=$DOMAIN_NAME \
  --parameters internalHostName=$INTERNAL_HOST_NAME \
  --parameters publicDnsZoneResourceGroup=$PUBLIC_DNS_ZONE_RG_NAME

CLUSTER_NAME=$(az deployment group show --resource-group $RG_NAME --name infra-deployment --query 'properties.outputs.aksClusterName.value' -o tsv)
az aks get-credentials -g $RG_NAME -n $CLUSTER_NAME --admin

###################
# install NGINX 
###################

# Add the ingress-nginx repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Use Helm to deploy an NGINX ingress controller
helm install $NGINX_INGRESS_SERVICE ingress-nginx/ingress-nginx \
  --version 4.3.0 \
  --namespace $NGINX_INGRESS_NAMESPACE \
  --create-namespace \
  --set controller.replicaCount=2 \
  --set controller.nodeSelector."kubernetes\.io/os"=linux \
  --set controller.admissionWebhooks.patch.nodeSelector."kubernetes\.io/os"=linux \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
  --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
  -f ./manifests/internal-ingress.yaml

# Create a namespace
kubectl create ns $APP_NAMESPACE

# Deploy the application
kubectl apply -f https://raw.githubusercontent.com/openservicemesh/osm-docs/release-v1.2/manifests/samples/httpbin/httpbin.yaml -n $APP_NAMESPACE

# create k8s secret for Tls cert
kubectl create secret tls $PRIVATE_CERT_NAME --key $PRIVATE_KEY_FILE --cert $PRIVATE_CERT_FILE -n $APP_NAMESPACE

######################
# Configure Ingress 
######################

# wait for the nginx controller to come up
sleep 60s

# apply Ingress & IngressBackend configuration
kubectl apply -f - << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: $APP_NAMESPACE
  namespace: $APP_NAMESPACE
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/use-regex: "true"
    nginx.ingress.kubernetes.io/rewrite-target: /$1
    nginx.ingress.kubernetes.io/proxy-ssl-secret: "$APP_NAMESPACE/$PRIVATE_CERT_NAME"
    nginx.ingress.kubernetes.io/proxy-ssl-verify: "on"
    nginx.ingress.kubernetes.io/proxy-ssl-name: "internal.nginx.$DOMAIN_NAME"
spec:
  tls:
  - hosts:
    - "internal.nginx.$DOMAIN_NAME"
    secretName: $PRIVATE_CERT_NAME
  ingressClassName: nginx
  rules:
  - host: internal.nginx.$DOMAIN_NAME
    http:
      paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: httpbin
              port:
                number: 14001
EOF

# wait for the Ingress chamge to apply
sleep 15s

# test the connection from Application Gateway
curl "https://httpbin.$DOMAIN_NAME"
