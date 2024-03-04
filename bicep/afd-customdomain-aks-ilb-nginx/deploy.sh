LOCATION='australiaeast'
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
K8S_VERSION='1.28.3'
PREFIX='afd-aks-nginx-ilb'
RG_NAME="$PREFIX-rg"
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
export TENANT_ID=$(az account show --query tenantId -o tsv)
export KV_NAME="$PREFIX-akv"
export CERT_NAME=aks-ingress-cert
export NAMESPACE='hello-world'
CURRENT_USER=$(az ad signed-in-user show --query id -o tsv)
NGINX_NAMESPACE='ingress'
APP_NAMESPACE='demo'
NGINX_SERVICE_ACCOUNT_NAME='ingress-nginx'
SSL_CERT_NAME='star-bellee-net'
CERT_CN='gateway.bellee.net'
SOURCE_ADDRESS_PREFIX=$(curl ifconfig.me)

source ./.env

# create resource group
az group create --location $LOCATION --name $RG_NAME

# purge deleted key vaults
az keyvault list-deleted --query [].name | jq -c '.[]' -r | while read kv; do
    az keyvault purge --name "$kv" --location $LOCATION --no-wait
done

# no deleted KVs should now be listed
az keyvault list-deleted --query [].name


# create key vault
KEYVAULT_SCOPE=$(az deployment group create \
  --resource-group $RG_NAME \
  --name kv-deployment \
  --template-file ./modules/keyvault.bicep \
  --parameters location=$LOCATION \
  --parameters prefix=$PREFIX \
  --query 'properties.outputs.id.value' -o tsv)

KV_NAME=$(az deployment group show \
  --resource-group $RG_NAME \
  --name kv-deployment \
  --query 'properties.outputs.name.value' -o tsv)

# grant the runner of this script access to the key vault
az role assignment create --role 'Key Vault Administrator' --assignee $CURRENT_USER --scope $KEYVAULT_SCOPE

# generate self-signed certificate & convert to .pfx
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -out ./certs/aks-ingress-tls.crt \
  -keyout ./certs/aks-ingress-tls.key \
  -subj "/CN=$CERT_CN/O=aks-ingress-tls" \
  -addext "subjectAltName = DNS:$CERT_CN"

# convert certificate to PFX and import certificate to key vault
# openssl pkcs12 -export -in ./certs/aks-ingress-tls.crt -inkey ./certs/aks-ingress-tls.key -out ./certs/$SSL_CERT_NAME.pfx
# openssl pkcs12 -export -in ./certs/$SSL_CERT_NAME.crt -inkey ./certs/$SSL_CERT_NAME.key -out ./certs/$SSL_CERT_NAME.pfx
# az keyvault certificate import --vault-name $KV_NAME -n $SSL_CERT_NAME -f ./certs/$SSL_CERT_NAME.pfx
az keyvault certificate import --vault-name $KV_NAME -n $SSL_CERT_NAME -f ./certs/$SSL_CERT_NAME.pfx

# deploy the rest of the infrastructure
az deployment group create \
  --resource-group $RG_NAME \
  --name infra-deployment \
  --template-file ./main.bicep \
  --parameters @main.parameters.json \
  --parameters location=$LOCATION \
  --parameters sshPublicKey="$SSH_KEY" \
  --parameters adminGroupObjectID=$ADMIN_GROUP_OBJECT_ID \
  --parameters k8sVersion=$K8S_VERSION \
  --parameters dnsPrefix=$PREFIX \
  --parameters sourceAddressPrefix=$SOURCE_ADDRESS_PREFIX

# get AKS credentials
CLUSTER_NAME=$(az deployment group show --resource-group $RG_NAME --name infra-deployment --query 'properties.outputs.aksClusterName.value' -o tsv)
az aks get-credentials -g $RG_NAME -n $CLUSTER_NAME --admin

# assign KeyVault CSI driver user managed identity 'Key Vault Administrator' role
export KV_CSI_IDENTITY_CLIENT_ID=$(az aks show -g $RG_NAME -n $CLUSTER_NAME --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv)
export KV_CSI_IDENTITY_RESOURCE_ID=$(az aks show -g $RG_NAME -n $CLUSTER_NAME --query addonProfiles.azureKeyvaultSecretsProvider.identity.resourceId -o tsv)
export AKS_NODE_RG_NAME=$(az aks show -g $RG_NAME -n $CLUSTER_NAME --query nodeResourceGroup -o tsv)
export BASTION_NAME=$(az network bastion list -g $RG_NAME --query [0].name -o tsv)
export VM_RESOURCE_ID=$(az vm list -g $RG_NAME --query [0].id -o tsv)
export WORKSPACE_ID=$(az monitor log-analytics workspace list -g $RG_NAME --query [0].id -o tsv)

az role assignment create --role 'Key Vault Administrator' --assignee $KV_CSI_IDENTITY_CLIENT_ID --scope $KEYVAULT_SCOPE

# create secret provider class
kubectl create namespace $APP_NAMESPACE

cat <<EOF | kubectl apply -f -
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-kvname-user-msi
  namespace: $APP_NAMESPACE
spec:
  provider: azure
  secretObjects:                            # secretObjects defines the desired state of synced K8s secret objects
    - secretName: ingress-tls-csi
      type: kubernetes.io/tls
      data: 
        - objectName: $SSL_CERT_NAME
          key: tls.key
        - objectName: $SSL_CERT_NAME
          key: tls.crt
  parameters:
    usePodIdentity: "false"
    useVmIdentity: "false"
    clientID: "$KV_CSI_IDENTITY_CLIENT_ID" # set clientId to use Workload Identity - NOTE: all parameter names are case sensitive!
    keyvaultName: $KV_NAME                 # the name of the AKV instance
    objects: |
      array:
        - |
          objectName: $SSL_CERT_NAME
          objectType: secret
    tenantId: $TENANT_ID                    # the tenant ID of the AKV instance
EOF

# create federated identity configuration for NGINX controller
export KV_CSI_IDENTITY_RESOURCE_NAME=$(az identity show --ids $KV_CSI_IDENTITY_RESOURCE_ID --query name -o tsv)
export AKS_OIDC_ISSUER="$(az aks show -n $CLUSTER_NAME -g $RG_NAME --query "oidcIssuerProfile.issuerUrl" -o tsv)"

az identity federated-credential create --name 'nginx-identity-federation' \
  --identity-name $KV_CSI_IDENTITY_RESOURCE_NAME \
  --resource-group $AKS_NODE_RG_NAME \
  --issuer $AKS_OIDC_ISSUER \
  --subject "system:serviceaccount:$APP_NAMESPACE:$NGINX_SERVICE_ACCOUNT_NAME" \
  --audiences api://AzureADTokenExchange

sleep 20

# Add the ingress-nginx repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# install NGINX Ingress Controller
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --create-namespace \
  --namespace $APP_NAMESPACE \
  --set controller.replicaCount=2 \
  --set controller.nodeSelector."kubernetes\.io/os"=linux \
  --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
  --set serviceAccount.annotations."azure\.workload\.identity/client-id"=$KV_CSI_IDENTITY_CLIENT_ID \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
  -f - <<EOF
controller:
  service:
    annotations:
      service.beta.kubernetes.io/azure-load-balancer-internal: "true"
      service.beta.kubernetes.io/azure-load-balancer-internal-subnet: "aks-lb-subnet"
      service.beta.kubernetes.io/azure-pls-create: "true"
      service.beta.kubernetes.io/azure-pls-name: "myServicePLS"
      service.beta.kubernetes.io/azure-pls-ip-configuration-subnet: pls-subnet
      service.beta.kubernetes.io/azure-pls-ip-configuration-ip-address-count: "1"
      service.beta.kubernetes.io/azure-pls-proxy-protocol: "false"
      service.beta.kubernetes.io/azure-pls-visibility: "*"
      service.beta.kubernetes.io/azure-pls-auto-approval: "*"
  podLabels:
    azure.workload.identity/use: "true"
  extraVolumes:
      - name: secrets-store-inline
        csi:
          driver: secrets-store.csi.k8s.io
          readOnly: true
          volumeAttributes:
            secretProviderClass: "azure-kvname-user-msi"
  extraVolumeMounts:
      - name: secrets-store-inline
        mountPath: "/mnt/secrets-store"
        readOnly: true
EOF

sleep 120

export PRIVATE_LINK_SERVICE_ID=$(az network private-link-service list -g $AKS_NODE_RG_NAME -o tsv --query [0].id)

az deployment group create \
  --resource-group $RG_NAME \
  --name afd-deployment \
  --template-file ./modules/afd.bicep \
  --parameters location=$LOCATION \
  --parameters originFqdn=$CERT_CN \
  --parameters privateLinkServiceId=$PRIVATE_LINK_SERVICE_ID \
  --parameters workspaceId=$WORKSPACE_ID \
  --parameters keyVaultName=$KV_NAME

sleep 20

# create pod & service
cat <<EOF | kubectl apply -f -
kind: Namespace
apiVersion: v1
metadata:
  name: $APP_NAMESPACE
  labels:
    name: $APP_NAMESPACE
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aks-helloworld
  namespace: $APP_NAMESPACE
spec:
  replicas: 1
  selector:
    matchLabels:
      app: aks-helloworld
  template:
    metadata:
      labels:
        app: aks-helloworld
    spec:
      containers:
      - name: aks-helloworld
        image: mcr.microsoft.com/azuredocs/aks-helloworld:v1
        ports:
        - containerPort: 80
        env:
        - name: TITLE
          value: "Welcome to Azure Kubernetes Service (AKS)"
        resources:
          requests:
            cpu: 250m
            memory: 250Mi
          limits:
            cpu: 500m
            memory: 500Mi
---
apiVersion: v1
kind: Service
metadata:
  name: aks-helloworld
  namespace: $APP_NAMESPACE
spec:
  selector:
    app: aks-helloworld
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
EOF

# create ingress
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-tls
  namespace: $APP_NAMESPACE
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
  - host: gateway.bellee.net
    http:
      paths:
      - path: /hello-world
        pathType: Prefix
        backend:
          service:
            name: aks-helloworld
            port:
              number: 80
      - path: /
        pathType: Prefix      
        backend:
          service:
            name: aks-helloworld
            port:
              number: 80
  tls:
  - hosts:
    - gateway.bellee.net
    secretName: ingress-tls-csi
EOF

# list secrets mounted to first NGINX controller pod
NGINX_POD_NAMES=$(kubectl get pod -l 'app.kubernetes.io/name=ingress-nginx' -n $APP_NAMESPACE -o json | jq .items[].metadata.name -r)
kubectl exec -it $NGINX_POD_NAMES[0] -n $APP_NAMESPACE -- ls /mnt/secrets-store

# test TLS connectivity to ingress controller
#
# ssh to linux jumpbox & test ingress
# copy public certificate to trusted certificate store on linux jumpbox
rm ./certs/cert.crt
az keyvault certificate download --vault-name $KV_NAME -n $SSL_CERT_NAME -f ./certs/cert.crt -e PEM && /
openssl x509 -in ./certs/cert.crt -inform PEM -noout -sha1 -fingerprint

az network bastion ssh \
  --name $BASTION_NAME \
  --resource-group $RG_NAME \
  --target-resource-id $VM_RESOURCE_ID \
  --auth-type ssh-key \
  --username localadmin \
  --ssh-key "$SSH_KEY"

# test e2e connectivity
curl https://$CERT_CN/hello-world -v

ILB_IP_ADDRESS=$(az network lb show -g $AKS_NODE_RG_NAME -n kubernetes-internal --query frontendIPConfigurations[0].privateIPAddress -o tsv)
# or
ILB_IP_ADDRESS=$(kubectl get services --namespace $APP_NAMESPACE  ingress-nginx-controller --output jsonpath='{.status.loadBalancer.ingress[0].ip}')

# run these commands in the ssh session to add the self-signed certificate to the vm ca-certificate store
# so that we don't need to use curl's '-k' flag to ignore TLS validation errors

  # sudo cp /tmp/cert.crt /usr/local/share/ca-certificates
  # sudo update-ca-certificates --fresh

  # test the ingress controller using curl
  #  curl https://gateway.bellee.net/hello-world --resolve gateway.bellee.net:443:10.0.16.4
