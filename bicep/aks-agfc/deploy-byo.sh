# Login to your Azure subscription.
AKS_NAME='aks-agc-cluster'
RESOURCE_GROUP="$AKS_NAME-rg"
LOCATION="northcentralus"
VM_SIZE='Standard_D4as_v5'
IDENTITY_RESOURCE_NAME='azure-alb-identity'
AGFC_NAME='alb-test' # Name of the Application Gateway for Containers resource to be created
FRONTEND_NAME='test-frontend'
ALB_SUBNET_NAME='agc-subnet'
ASSOCIATION_NAME='association-test'

# Register required resource providers on Azure.
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.Network
az provider register --namespace Microsoft.NetworkFunction
az provider register --namespace Microsoft.ServiceNetworking

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
mcResourceGroup=`az aks show --resource-group $RESOURCE_GROUP --name $AKS_NAME --query "nodeResourceGroup" -o tsv`

echo "Creating identity '$IDENTITY_RESOURCE_NAME' in resource group $RESOURCE_GROUP"
principalId=`az identity create --resource-group $RESOURCE_GROUP --name $IDENTITY_RESOURCE_NAME --query principalId -otsv`

echo "Waiting 60 seconds to allow for replication of the identity..."
sleep 60

echo "Apply Reader role to the AKS managed cluster resource group for the newly provisioned identity"
az role assignment create --assignee-object-id $principalId \
    --resource-group $mcResourceGroup \
    --role "acdd72a7-3385-48ef-bd42-f606fba81ae7" # Reader role

echo "Setup federation with AKS OIDC issuer"
AKS_OIDC_ISSUER="$(az aks show -n "$AKS_NAME" -g "$RESOURCE_GROUP" --query "oidcIssuerProfile.issuerUrl" -o tsv)"
az identity federated-credential create --name $IDENTITY_RESOURCE_NAME \
    --identity-name $IDENTITY_RESOURCE_NAME \
    --resource-group $RESOURCE_GROUP \
    --issuer "$AKS_OIDC_ISSUER" \
    --subject "system:serviceaccount:azure-alb-system:alb-controller-sa"

# install ALB controller with Helm
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME

clientId=`az identity show --resource-group $RESOURCE_GROUP --name $IDENTITY_RESOURCE_NAME --query clientId -o tsv`

helm install alb-controller oci://mcr.microsoft.com/application-lb/charts/alb-controller \
    --version 0.4.023901 \
    --set albController.podIdentity.clientID=$clientId

# verify installation
kubectl get pods -n azure-alb-system
kubectl get gatewayclass azure-alb-external -o yaml

# create AGC resource
az network alb create -g $RESOURCE_GROUP -n $AGFC_NAME

# create frontend resource
az network alb frontend create -g $RESOURCE_GROUP -n $FRONTEND_NAME --alb-name $AGFC_NAME

# create association resource
VNET_NAME=`az network vnet list -g $mcResourceGroup --query [].name -o tsv`

# delegate subnet
az network vnet subnet update \
    --resource-group $mcResourceGroup  \
    --name $ALB_SUBNET_NAME \
    --vnet-name $VNET_NAME \
    --delegations 'Microsoft.ServiceNetworking/trafficControllers'

ALB_SUBNET_ID=`az network vnet subnet list --resource-group $mcResourceGroup \
    --vnet-name $VNET_NAME \
    --query "[?name=='$ALB_SUBNET_NAME'].id" \
    --output tsv`

echo $ALB_SUBNET_ID

# delegate permissions to managed identity
resourceGroupId=$(az group show --name $RESOURCE_GROUP --query id -otsv)
principalId=$(az identity show -g $RESOURCE_GROUP -n $IDENTITY_RESOURCE_NAME --query principalId -otsv)

# Delegate AppGw for Containers Configuration Manager role to RG containing Application Gateway for Containers resource
az role assignment create --assignee-object-id $principalId --scope $resourceGroupId --role "fbc52c3f-28ad-4303-a892-8a056630b8f1" # 'AppGw for Containers Configuration Manager'

# Delegate Network Contributor permission for join to association subnet
az role assignment create --assignee-object-id $principalId --scope $ALB_SUBNET_ID --role "4d97b98b-1d4f-4787-a291-c67834d212e7" # '4d97b98b-1d4f-4787-a291-c67834d212e7'

# create association resource
az network alb association create -g $RESOURCE_GROUP -n $ASSOCIATION_NAME --alb-name $AGFC_NAME --subnet $ALB_SUBNET_ID

#########################
# Scenarios
#########################

#########################
# backend mTLS 
kubectl apply -f ./backend-mtls/deployment.yaml # https://trafficcontrollerdocs.blob.core.windows.net/examples/https-scenario/end-to-end-ssl-with-backend-mtls/deployment.yaml

RESOURCE_ID=$(az network alb show --resource-group $RESOURCE_GROUP --name $AGFC_NAME --query id -o tsv)

# create gateway Object
sed "s|<RESOURCE_ID>|$RESOURCE_ID|g;s|<FRONTEND_NAME>|$FRONTEND_NAME|g" ./backend-mtls/gateway.yaml | kubectl apply -f -

# verify gateway
kubectl get gateway gateway-01 -n test-infra -o yaml

# create HTTP route
kubectl apply -f ./backend-mtls/http-route.yaml

# verify route
kubectl get httproute -n test-infra https-route -o yaml

# create backend TLS policy
kubectl apply -f ./backend-mtls/tls-policy.yaml

# verify TLS policy
kubectl get backendtlspolicy -n test-infra mtls-app-tls-policy -o yaml

# test
fqdn=$(kubectl get gateway gateway-01 -n test-infra -o jsonpath='{.status.addresses[0].value}')
curl --insecure https://$fqdn/

#########################
# SSL Offloading

kubectl apply -f ./ssl-offload/deployment.yaml # https://trafficcontrollerdocs.blob.core.windows.net/examples/https-scenario/end-to-end-ssl-with-backend-mtls/deployment.yaml

RESOURCE_ID=$(az network alb show --resource-group $RESOURCE_GROUP --name $AGFC_NAME --query id -o tsv)

# create apps
kubectl apply -f ./ssl-offload/mtls-app.yaml
kubectl apply -f ./ssl-offload/echo-app.yaml

# create gateway Object
sed "s|<RESOURCE_ID>|$RESOURCE_ID|g;s|<FRONTEND_NAME>|$FRONTEND_NAME|g" ./ssl-offload/gateway.yaml | kubectl apply -f -

# verify gateway
kubectl get gateway gateway-01 -n test-infra -o yaml

# create http-route
kubectl apply -f ./ssl-offload/http-route.yaml

# verify http-route
kubectl get httproute https-route -n test-infra -o yaml

fqdn=$(kubectl get gateway gateway-01 -n test-infra -o jsonpath='{.status.addresses[0].value}')
curl --insecure https://$fqdn/

#########################
# traffic-split

RESOURCE_ID=$(az network alb show --resource-group $RESOURCE_GROUP --name $AGFC_NAME --query id -o tsv)

# create apps
kubectl apply -f ./traffic-split/deployment.yaml # https://trafficcontrollerdocs.blob.core.windows.net/examples/traffic-split-scenario/deployment.yaml

# create gateway Object
kubectl get gateway gateway-01 -n test-infra -o yaml

# create http-route 
kubectl apply -f ./traffic-split/http-route.yaml

# verify http-route
kubectl get httproute -n test-infra traffic-split-route -o yaml

fqdn=$(kubectl get gateway gateway-01 -n test-infra -o jsonpath='{.status.addresses[0].value}')

curl https://$fqdn --insecure

# this curl command will return 50% of the responses from backend-v1
# and the remaining 50% of the responses from backend-v2
watch -n 1 curl https://$fqdn --insecure


# this curl command will return 50% of the responses from backend-v1
# and the remaining 50% of the responses from backend-v2
watch -n 1 curl $fqdn


