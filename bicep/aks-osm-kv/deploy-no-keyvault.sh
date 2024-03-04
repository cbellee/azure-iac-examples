LOCATION='australiaeast'
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
ADMIN_GROUP_OBJECT_ID="f6a900e2-df11-43e7-ba3e-22be99d3cede"
LATEST_K8S_VERSION=$(az aks get-versions -l $LOCATION | jq -r -c '[.orchestrators[] | .orchestratorVersion][-1]')
RG_NAME='aks-osm-kv-rg'
DNS_PREFIX='aks-csi-workload-identity'

az group create --location $LOCATION --name $RG_NAME

az deployment group create \
    --resource-group $RG_NAME \
    --name aks-deployment \
    --template-file ./main.bicep \
    --parameters @main.parameters.json \
    --parameters location=$LOCATION \
    --parameters sshPublicKey="$SSH_KEY" \
    --parameters adminGroupObjectID=$ADMIN_GROUP_OBJECT_ID \
    --parameters aksVersion=$LATEST_K8S_VERSION \
    --parameters dnsPrefix=$DNS_PREFIX

CLUSTER_NAME=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.aksClusterName.value' -o tsv)
az aks get-credentials -g $RG_NAME -n $CLUSTER_NAME --admin

az aks update -g $RG_NAME -n $CLUSTER_NAME --enable-secret-rotation
KUBELET_IDENTITY_CLIENT_ID=$(az aks show -n $CLUSTER_NAME -g $RG_NAME --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv)

openssl genrsa -out ./certs/ca.pem 2048
openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in ./certs/ca.pem -out ./certs/ca.key
openssl req -x509 -new -nodes -key ./certs/ca.key -sha256 -days 1825 -out ./certs/ca.crt -subj "/C=AU/ST=NSW/L=Sydney/O=IT/CN=osm.kainiindustries.net"

# patch root-cert-secret-template.yaml with base64 encoded private key & certificate
p=$(echo $(cat ./certs/ca.key | base64 -w 0))
c=$(echo $(cat ./certs/ca.crt | base64 -w 0))
sed "s/<<BASE_64_CERTIFICATE>>/${c}/g; s/<<BASE_64_PRIVATE_KEY>>/${p}/g" ./manifests/root-cert-secret-template.yaml > ./manifests/root-cert-secret.yaml

# create root certificate secret object in kubernetes
kubectl apply -f ./manifests/root-cert-secret.yaml -n osm-system

helm repo add osm https://openservicemesh.github.io/osm
helm repo update
helm install my-osm osm/osm --namespace osm-system
