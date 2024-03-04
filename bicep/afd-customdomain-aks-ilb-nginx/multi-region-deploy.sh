PREFIX='afd-aks-pls'
LOCATIONS=('australiaeast' 'australiasoutheast')
AFD_RG_NAME="${PREFIX}-global-rg"
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
K8S_VERSION='1.28.3'
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
TENANT_ID=$(az account show --query tenantId -o tsv)
CERT_NAME=aks-ingress-cert
CURRENT_USER_OID=$(az ad signed-in-user show --query id -o tsv)
NGINX_NAMESPACE='ingress'
APP_NAMESPACE='demo'
NGINX_SERVICE_ACCOUNT_NAME='ingress-nginx'
SSL_CERT_NAME='star-bellee-net'
CERT_CN='gateway.bellee.net'
DOMAIN_NAME='bellee.net'

source ./.env

# purge deleted key vaults
az keyvault list-deleted --query [].name | jq -c '.[]' -r | while read kv; do
    az keyvault purge --name "$kv" --location $LOCATION --no-wait
done

# no deleted KVs should now be listed
az keyvault list-deleted --query [].name

# deploy the rest of the infrastructure to both regions
az deployment sub create --name infra-deployment \
  --template-file ./main-multi-region.bicep \
  --location ${LOCATIONS[0]} \
  --parameters @main.multi-region.parameters.json \
  --parameters sshPublicKey="$SSH_KEY" \
  --parameters adminGroupObjectID=$ADMIN_GROUP_OBJECT_ID \
  --parameters k8sVersion=$K8S_VERSION \
  --parameters dnsPrefix=$PREFIX \
  --parameters userPrincipalId=${CURRENT_USER_OID}

# get deployment output
OUTPUT=$(az deployment sub show \
  --name infra-deployment \
  --query 'properties.outputs' -o json)

KV_SCOPES=($(echo $OUTPUT | jq '.keyVaults.value' | jq '.[].id' -r))
KV_NAMES=($(echo $OUTPUT | jq '.keyVaults.value' | jq '.[].name' -r))
VM_RESOURCE_IDS=($(echo $OUTPUT | jq '.virtualMachines.value' | jq '.[].id' -r))

# import certificate to key vault
for i in {0..1}; do
  az keyvault certificate import --vault-name ${KN[$i]} -n $SSL_CERT_NAME -f ./certs/$SSL_CERT_NAME.pfx
done

# get AKS credentials
CLUSTER_NAMES+=($(echo $OUTPUT | jq '.clusters.value' | jq '.[].name' -r))
CLUSTER_RGS+=($(echo $OUTPUT | jq '.clusters.value' | jq '.[].resourceGroup' -r))
CLUSTER_NODE_RGS+=($(echo $OUTPUT | jq '.clusters.value' | jq '.[].nodeResourceGroup' -r))
CLUSTER_CSI_CLIENT_IDS+=($(echo $OUTPUT | jq '.clusters.value'| jq '.[].keyVaultProviderClientId' -r))
CLUSTER_CSI_RESOURCE_IDS+=($(echo $OUTPUT | jq '.clusters.value' | jq '.[].keyVaultProviderResourceId' -r))
CLUSTER_OIDC_ISSUER_URL+=($(echo $OUTPUT | jq '.clusters.value' | jq '.[].oidcIssuer' -r))

for i in {0..1}; do
az aks get-credentials -g ${CLUSTER_RGS[$i]} -n ${CLUSTER_NAMES[$i]}

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
    clientID: "${CLUSTER_CSI_CLIENT_IDS[$i]}" # set clientId to use Workload Identity - NOTE: all parameter names are case sensitive!
    keyvaultName: "${KV_NAMES[$i]}"                # the name of the AKV instance
    objects: |
      array:
        - |
          objectName: $SSL_CERT_NAME
          objectType: secret
    tenantId: $TENANT_ID                    # the tenant ID of the AKV instance
EOF

CLUSTER_CSI_RESOURCE_NAME=$(az identity show --ids ${CLUSTER_CSI_RESOURCE_IDS[$i]} --query name -o tsv)

az identity federated-credential create --name 'nginx-identity-federation' \
  --identity-name  $CLUSTER_CSI_RESOURCE_NAME \
  --resource-group "${CLUSTER_NODE_RGS[$i]}" \
  --issuer ${CLUSTER_OIDC_ISSUER_URL[$i]} \
  --subject "system:serviceaccount:$APP_NAMESPACE:$NGINX_SERVICE_ACCOUNT_NAME" \
  --audiences api://AzureADTokenExchange

done

sleep 20

for i in {0..1}; do
kubectl config use-context ${CLUSTER_NAMES[$i]}

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
  --set serviceAccount.annotations."azure\.workload\.identity/client-id"=${CLUSTER_CSI_CLIENT_IDS[$i]} \
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
done

sleep 120

AFD_OUTPUT=$(az deployment group create \
  --resource-group ${CLUSTER_RGS[0]} \
  --name afd-deployment \
  --template-file ./modules/afd.bicep \
  --parameters keyVaultName=${KV_NAMES[0]} \
  --parameters prefix=$PREFIX \
  --parameters originFqdn=$CERT_CN \
  --query properties.outputs -o json)

ORIGIN_GROUP_NAME=$(echo $AFD_OUTPUT | jq '.originGroupName.value' -r)
FRONT_DOOR_NAME=$(echo $AFD_OUTPUT | jq '.frontDoorName.value' -r)

for i in {0..1}; do
PRIVATE_LINK_SERVICE_ID=$(az network private-link-service list -g ${CLUSTER_NODE_RGS[$i]} -o tsv --query [].id)

az deployment group create \
  --resource-group ${CLUSTER_RGS[$i]} \
  --name afd-origin-deployment \
  --template-file ./modules/afd-origin-route.bicep \
  --parameters originFqdn=$CERT_CN \
  --parameters privateLinkServiceId=$PRIVATE_LINK_SERVICE_ID \
  --parameters domainName=$DOMAIN_NAME \
  --parameters frontDoorName=$FRONT_DOOR_NAME \
  --parameters originGroupName=$ORIGIN_GROUP_NAME

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
  - host: $CERT_CN
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
    - $CERT_CN
    secretName: ingress-tls-csi
EOF

done

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
