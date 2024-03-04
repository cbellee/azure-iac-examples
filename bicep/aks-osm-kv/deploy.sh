LOCATION='australiaeast'
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
ADMIN_GROUP_OBJECT_ID="f6a900e2-df11-43e7-ba3e-22be99d3cede"
LATEST_K8S_VERSION=$(az aks get-versions -l $LOCATION | jq -r -c '[.orchestrators[] | .orchestratorVersion][-1]')
RG_NAME="aks-osm-kv-rg"
UAMI='akv-csi-user-assigned-identity'
SERVICE_ACCOUNT_NAME="workload-identity-sa" 
OSM_SYSTEM_NAMESPACE="osm-system"
FEDERATED_IDENTITY_NAME="aksfederatedidentity"
CERTIFICATE_OBJECT_NAME="kainiindustries-net-bundle"
DNS_PREFIX='aks-csi-workload-identity'

# add preview Az CLI extension
az feature register --namespace "Microsoft.ContainerService" --name "EnableWorkloadIdentityPreview"
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/EnableWorkloadIdentityPreview')].{Name:name,State:properties.state}"
az provider register -n Microsoft.ContainerService
az extension add --name aks-preview

# create resource group
az group create --location $LOCATION --name $RG_NAME

# deploy bicep template
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

# get bicep deployment outputs
CLUSTER_NAME=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.aksClusterName.value' -o tsv)
KV_NAME=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.keyVaultName.value' -o tsv)
UAMI_NAME=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.uamiName.value' -o tsv)
UAMI_CLIENT_ID=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.uamiClientId.value' -o tsv)
UAMI_TENANT=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.uamiTenantId.value' -o tsv)
KUBELET_IDENTITY_CLIENT_ID=$(az aks show -n $CLUSTER_NAME -g $RG_NAME --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv)

echo "CLUSTER_NAME: ${CLUSTER_NAME}"
echo "KV_NAME: ${KV_NAME}"
echo "UAMI_NAME: ${UAMI_NAME}"
echo "UAMI_CLIENT_ID: ${UAMI_CLIENT_ID}"
echo "UAMI_TENANT: ${UAMI_TENANT}"
echo "KUBELET_IDENTITY_CLIENT_ID: ${KUBELET_IDENTITY_CLIENT_ID}"

# create Root CA private key
openssl genrsa -out ./certs/ca.pem 2048

# convert the root CA private key to pkcs8 format
openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in ./certs/ca.pem -out ./certs/ca.key

# create a certificate signing request
openssl req -x509 -new -nodes -key ./certs/ca.key -sha256 -days 1825 -out ./certs/ca.crt -subj "/C=AU/ST=NSW/L=Sydney/O=IT/CN=osm.kainiindustries.net"

# concatenate certificate and private key to a single .PEM file
cat ./certs/ca.crt ./certs/ca.key > ./certs/bundle.pem

# upload .PEM certificate to Azure Key Vault
az keyvault certificate import --vault-name $KV_NAME -n kainiindustries-net-bundle -f ./certs/bundle.pem

az keyvault certificate show --vault-name $KV_NAME --name kainiindustries-net-bundle

# get aks cluster credentials
az aks get-credentials -g $RG_NAME -n $CLUSTER_NAME --admin

# ensure provider is installed
kubectl get pods -n kube-system -l 'app in (secrets-store-csi-driver, secrets-store-provider-azure)'

# install Workload Identity
AKS_OIDC_ISSUER="$(az aks show --resource-group $RG_NAME --name $CLUSTER_NAME --query "oidcIssuerProfile.issuerUrl" -o tsv)"
echo "AKS_OIDC_ISSUER: ${AKS_OIDC_ISSUER}"

# create osm-system namespace
kubectl create namespace $OSM_SYSTEM_NAMESPACE

# create ServiceAccount
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: ${UAMI_CLIENT_ID}
  labels:
    azure.workload.identity/use: "true"
  name: ${SERVICE_ACCOUNT_NAME}
  namespace: ${OSM_SYSTEM_NAMESPACE}
EOF

# create Federated credential
az identity federated-credential create \
    --name $FEDERATED_IDENTITY_NAME \
    --identity-name $UAMI_NAME \
    --resource-group $RG_NAME \
    --issuer ${AKS_OIDC_ISSUER} \
    --subject system:serviceaccount:${OSM_SYSTEM_NAMESPACE}:${SERVICE_ACCOUNT_NAME}

# create SecretProviderClass
cat <<EOF | kubectl apply -f -
# This is a SecretProviderClass example using workload identity to access your key vault
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: azure-kv-csi-workload-identity # needs to be unique per namespace
  namespace: ${OSM_SYSTEM_NAMESPACE}
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "false"          
    clientID: "${UAMI_CLIENT_ID}" # Setting this to use workload identity
    keyvaultName: ${KV_NAME}       # Set to the name of your key vault
    tenantId: "${UAMI_TENANT}"        # The tenant ID of the key vault
    cloudName: "AzurePublicCloud"  # [OPTIONAL for Azure] if not provided, the Azure environment defaults to AzurePublicCloud
    objects: |
        array:
        - |
            objectName: kainiindustries-net-bundle
            objectType: cert
            objectAlias: root-certificate
        - |
            objectName: kainiindustries-net-bundle
            objectType: secret
            objectAlias: root-certificate-private-key
  secretObjects:
    - secretName: osm-ca-bundle
      type: Opaque
      labels:
        secret: osm-ca-bundle
      data:
        - objectName: root-certificate
          key: ca.crt
        - objectName: root-certificate-private-key
          key: private.key
EOF

# create Pod to mount KV secrets and K8S Secret object
cat <<EOF | kubectl apply -n $OSM_SYSTEM_NAMESPACE -f -
# This is a sample pod definition for using SecretProviderClass and the user-assigned identity to access your key vault
kind: Pod
apiVersion: v1
metadata:
  name: busybox-secrets-store-inline-user-msi
spec:
  containers:
    - name: busybox
      image: k8s.gcr.io/e2e-test-images/busybox:1.29-1
      command:
        - "/bin/sleep"
        - "10000"
      volumeMounts:
      - name: secrets-store01-inline
        mountPath: "/mnt/secrets-store"
        readOnly: true
  serviceAccountName: ${SERVICE_ACCOUNT_NAME}
  volumes:
    - name: secrets-store01-inline
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
          secretProviderClass: azure-kv-csi-workload-identity
EOF

# list pod & Secrets created in osm-system namespace
kubectl describe po busybox-secrets-store-inline-user-msi  -n $OSM_SYSTEM_NAMESPACE
kubectl get Secrets -n $OSM_SYSTEM_NAMESPACE
kubectl describe  Secrets osm-ca-bundle -n $OSM_SYSTEM_NAMESPACE
kubectl get secret osm-ca-bundle -n $OSM_SYSTEM_NAMESPACE -o jsonpath="{.data.ca\.crt}" | base64 -d
kubectl get secret osm-ca-bundle -n $OSM_SYSTEM_NAMESPACE -o jsonpath="{.data.private\.key}" | base64 -d

# update helm chart repo
helm repo add osm https://openservicemesh.github.io/osm
helm repo update

helm install my-osm osm/osm --namespace $OSM_SYSTEM_NAMESPACE

# install bookstore demo application
kubectl create namespace bookstore
kubectl create namespace bookbuyer
kubectl create namespace bookthief
kubectl create namespace bookwarehouse

# add namespaces to osm mesh
osm namespace add bookstore bookbuyer bookthief bookwarehouse

kubectl patch meshconfig osm-mesh-config -n $OSM_SYSTEM_NAMESPACE --patch '{"spec":{"traffic":{"enablePermissiveTrafficPolicyMode":true}}}' --type=merge

kubectl apply -f https://raw.githubusercontent.com/openservicemesh/osm-docs/release-v1.0/manifests/apps/bookbuyer.yaml
kubectl apply -f https://raw.githubusercontent.com/openservicemesh/osm-docs/release-v1.0/manifests/apps/bookthief.yaml
kubectl apply -f https://raw.githubusercontent.com/openservicemesh/osm-docs/release-v1.0/manifests/apps/bookstore.yaml
kubectl apply -f https://raw.githubusercontent.com/openservicemesh/osm-docs/release-v1.0/manifests/apps/bookwarehouse.yaml
kubectl apply -f https://raw.githubusercontent.com/openservicemesh/osm-docs/release-v1.0/manifests/apps/mysql.yaml

kubectl get pods,deployments,serviceaccounts -n bookbuyer
kubectl get pods,deployments,serviceaccounts -n bookthief
kubectl get pods,deployments,serviceaccounts,services,endpoints -n bookstore
kubectl get pods,deployments,serviceaccounts,services,endpoints -n bookwarehouse

# disable permissive mode (the default), which allows all pods in onboarded namspaces to communicate
kubectl patch meshconfig osm-mesh-config -n $OSM_SYSTEM_NAMESPACE --patch '{"spec":{"traffic":{"enablePermissiveTrafficPolicyMode":false}}}' --type=merge

# apply SMI policy to allow bookbuyer to buy books & prevent book thief
kubectl apply -f ./manifests/allow-bookbuyer-smi.yaml

#############################
# secret update
#############################

# remove secret
k delete secret osm-ca-bundle -n osm-system
# remove CSI pod
k delete po  busybox-secrets-store-inline-user-msi -n osm-system

# create newe root CA cert & key
# create Root CA private key
openssl genrsa -out ./certs/ca.pem 2048

# convert the root CA private key to pkcs8 format
openssl pkcs8 -topk8 -inform PEM -outform PEM -nocrypt -in ./certs/ca.pem -out ./certs/ca.key

# create a certificate signing request
openssl req -x509 -new -nodes -key ./certs/ca.key -sha256 -days 1825 -out ./certs/ca.crt -subj "/C=AU/ST=NSW/L=Sydney/O=IT/CN=osm.kainiindustries.net"

# concatenate certificate and private key to a single .PEM file
cat ./certs/ca.crt ./certs/ca.key > ./certs/bundle.pem

# upload .PEM certificate to Azure Key Vault
az keyvault certificate import --vault-name $KV_NAME -n kainiindustries-net-bundle -f ./certs/bundle.pem

# restart osm control plane when root certificate is updated in key vault 
# and sync to the cluster as a Kubernetes Secret
kubectl rollout restart deploy osm-controller -n $OSM_SYSTEM_NAMESPACE
kubectl rollout restart deploy osm-injector -n $OSM_SYSTEM_NAMESPACE
kubectl rollout restart deploy osm-bootstrap -n $OSM_SYSTEM_NAMESPACE

kubectl delete namespace bookstore
kubectl delete namespace bookbuyer
kubectl delete namespace bookthief
kubectl delete namespace bookwarehouse

# uninstall OSM
# helm uninstall my-osm osm/osm --namespace $OSM_SYSTEM_NAMESPACE