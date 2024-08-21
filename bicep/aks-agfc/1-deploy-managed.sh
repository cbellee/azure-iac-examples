# Login to your Azure subscription.
LOCATION="australiaeast"
LOCATION_SHORT="aue"
AKS_NAME="aks-agc-managed"
RESOURCE_GROUP="$AKS_NAME-rg"
VM_SIZE='Standard_D4ds_v5'
IDENTITY_RESOURCE_NAME='azure-alb-identity'
ALB_NAME='alb-agfc' # Application Gateway for Containers resource name
ALB_NAMESPACE='agfc' # K8S namespace for ALB resources
FRONTEND_NAME='alb-frontend'
ALB_SUBNET_NAME='agc-subnet'
ASSOCIATION_NAME='agc-association'
resourceProviders=('Microsoft.ContainerService' 'Microsoft.Network' 'Microsoft.NetworkFunction' 'Microsoft.ServiceNetworking')

# Register required resource providers on Azure.
function registerResourceProvider() {
    registrationState=$(az provider show --namespace $1 | jq .registrationState -r)
    if [ $registrationState != 'Registered' ]; then
        echo "Registering namespace $1"
        while [ $registrationState != 'Registered' ]; do
            sleep 5
            registrationState=$(az provider show --namespace $1 | jq .registrationState -r)
            echo "Registration state: $registrationState"
            echo "Waiting for registration of namespace $1 to complete..."
        done
        echo "Namespace '$1' successfully registered"
    else
        echo "Namespace '$1' already registered"
    fi
}

for provider in $(echo ${resourceProviders[@]}); do
    registerResourceProvider $provider
done

# install Azure CLI extensions
az extension add --name alb

# create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# create cluster
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $AKS_NAME \
    --location $LOCATION \
    --node-vm-size $VM_SIZE \
    --network-plugin azure \
    --enable-oidc-issuer \
    --enable-workload-identity \
    --generate-ssh-key

# create UMID & Federated Identity configuration
mcResourceGroup=$(az aks show --resource-group $RESOURCE_GROUP --name $AKS_NAME --query "nodeResourceGroup" -o tsv)
mcResourceGroupId=$(az group show --name $mcResourceGroup --query id -otsv)

echo "Creating identity '$IDENTITY_RESOURCE_NAME' in resource group $RESOURCE_GROUP"
principalId=`az identity create --resource-group $RESOURCE_GROUP --name $IDENTITY_RESOURCE_NAME --query principalId -otsv`

echo "Waiting 60 seconds to allow for replication of the identity..."
sleep 60

echo "Apply Reader role to the AKS managed cluster resource group for the newly provisioned identity"
az role assignment create --assignee-object-id $principalId \
    --scope $mcResourceGroupId \
    --role "acdd72a7-3385-48ef-bd42-f606fba81ae7" # Reader role

echo "Setup federation with AKS OIDC issuer"
AKS_OIDC_ISSUER="$(az aks show -n "$AKS_NAME" -g "$RESOURCE_GROUP" --query "oidcIssuerProfile.issuerUrl" -o tsv)"

az identity federated-credential create --name $IDENTITY_RESOURCE_NAME \
    --identity-name $IDENTITY_RESOURCE_NAME \
    --resource-group $RESOURCE_GROUP \
    --issuer "$AKS_OIDC_ISSUER" \
    --subject "system:serviceaccount:azure-alb-system:alb-controller-sa"

# install ALB controller with Helm
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME --admin

clientId=$(az identity show --resource-group $RESOURCE_GROUP --name $IDENTITY_RESOURCE_NAME --query clientId -o tsv)
helm install alb-controller oci://mcr.microsoft.com/application-lb/charts/alb-controller \
    --version 1.0.2 \
    --set albController.podIdentity.clientID=$clientId

# verify installation
kubectl get pods -n azure-alb-system
kubectl get gatewayclass azure-alb-external -o yaml

# create association resource
VNET_NAME=$(az network vnet list -g $mcResourceGroup --query [].name -o tsv)

# delegate subnet
az network vnet subnet create \
    --vnet-name $VNET_NAME \
    --name $ALB_SUBNET_NAME \
    --resource-group $mcResourceGroup \
    --address-prefixes '10.225.0.0/22' \
    --delegations 'Microsoft.ServiceNetworking/trafficControllers'

ALB_SUBNET_ID=`az network vnet subnet list --resource-group $mcResourceGroup \
    --vnet-name $VNET_NAME \
    --query "[?name=='$ALB_SUBNET_NAME'].id" \
    --output tsv`

# Delegate AppGw for Containers Configuration Manager role to RG containing Application Gateway for Containers resource
az role assignment create --assignee-object-id $principalId --scope $mcResourceGroupId --role "fbc52c3f-28ad-4303-a892-8a056630b8f1" # 'AppGw for Containers Configuration Manager'

# Delegate Network Contributor permission for join to association subnet
az role assignment create --assignee-object-id $principalId --scope $ALB_SUBNET_ID --role "4d97b98b-1d4f-4787-a291-c67834d212e7" # '4d97b98b-1d4f-4787-a291-c67834d212e7'

# create namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $ALB_NAMESPACE
EOF

# crate ALB resource in MC_ resource group
kubectl apply -f - <<EOF
apiVersion: alb.networking.azure.io/v1
kind: ApplicationLoadBalancer
metadata:
  name: $ALB_NAME
  namespace: $ALB_NAMESPACE
spec:
  associations:
  - $ALB_SUBNET_ID
EOF

# validate
kubectl get applicationloadbalancer $ALB_NAME -n $ALB_NAMESPACE -o yaml -w
