LOCATION='australiaeast'
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
K8S_VERSION='1.28.5'
PREFIX='aks-cni-overlay'
RG_NAME="aks-appgw-cni-overlay-blue-green-rg"
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
AKS_ADMIN_GROUP_NAME='aks-admin-group'
NGINX_INGRESS_NAMESPACE='ingress-nginx'
NGINX_INGRESS_SERVICE='ingress-nginx'
APP_NAMESPACE='test'
BACKEND_HOST_NAME='aks.test.internal'

# create AKS administrator group & add the current user to it
CURRENT_USER_OBJECT_ID=$(az ad signed-in-user show --query id -o tsv)
az ad group create --display-name $AKS_ADMIN_GROUP_NAME --mail-nickname $AKS_ADMIN_GROUP_NAME
az ad group member add --group $AKS_ADMIN_GROUP_NAME --member-id $CURRENT_USER_OBJECT_ID

# create resource group
az group create --location $LOCATION --name $RG_NAME

# grep IPs from internal-ingress-blue.yaml & internal-ingress-green.yaml
BLUE_INGRESS_PRIVATE_IP=$(cat ./manifests/internal-ingress-blue.yaml | grep -oE "\b[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}")
GREEN_INGRESS_PRIVATE_IP=$(cat ./manifests/internal-ingress-green.yaml | grep -oE "\b[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}.[0-9]{1,3}")

# deploy infrastructure
az deployment group create \
  --resource-group $RG_NAME \
  --name infra-deployment \
  --template-file ./main.bicep \
  --parameters @main.parameters.json \
  --parameters location=$LOCATION \
  --parameters sshPublicKey="$SSH_KEY" \
  --parameters adminGroupObjectID=$ADMIN_GROUP_OBJECT_ID \
  --parameters aksVersion=$K8S_VERSION \
  --parameters blueIngressPrivateIpAddress=$BLUE_INGRESS_PRIVATE_IP \
  --parameters greenIngressPrivateIpAddress=$GREEN_INGRESS_PRIVATE_IP \
  --parameters backendHostName=$BACKEND_HOST_NAME

BLUE_CLUSTER_NAME=$(az deployment group show --resource-group $RG_NAME --name infra-deployment --query 'properties.outputs.aksBlueClusterName.value' -o tsv)
GREEN_CLUSTER_NAME=$(az deployment group show --resource-group $RG_NAME --name infra-deployment --query 'properties.outputs.aksGreenClusterName.value' -o tsv)
ACR_NAME=$(az deployment group show --resource-group $RG_NAME --name infra-deployment --query 'properties.outputs.acrName.value' -o tsv)

export IMAGE_NAME="$ACR_NAME.azurecr.io/colourserver:latest"
az acr build -r $ACR_NAME -t $IMAGE_NAME .

# Add the ingress-nginx repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

#######################
# Blue Cluster config
#######################

export VERSION='v1'
export COLOUR='blue'
export LOCATION='australiaeast'

az aks get-credentials -g $RG_NAME -n $BLUE_CLUSTER_NAME --admin

# Use Helm to deploy an NGINX ingress controller
helm install $NGINX_INGRESS_SERVICE ingress-nginx/ingress-nginx \
  --namespace $NGINX_INGRESS_NAMESPACE \
  --create-namespace \
  --set controller.replicaCount=2 \
  --set controller.nodeSelector."kubernetes\.io/os"=linux \
  --set controller.admissionWebhooks.patch.nodeSelector."kubernetes\.io/os"=linux \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
  --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
  -f ./manifests/internal-ingress-blue.yaml

# wait for the nginx controller to come up
sleep 30s

# Create a namespace
kubectl create ns $APP_NAMESPACE

# Deploy the application
envsubst < ./manifests/colourserver.yaml | kubectl -n $APP_NAMESPACE apply -f -

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
spec:
  ingressClassName: nginx
  rules:
  - host: aks.test.internal
    http:
      paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: colour
              port:
                number: 80
EOF

#######################
# Green Cluster config
#######################

export VERSION='v1'
export COLOUR='green'
export LOCATION='australiaeast'

az aks get-credentials -g $RG_NAME -n $GREEN_CLUSTER_NAME --admin

# Use Helm to deploy an NGINX ingress controller
helm install $NGINX_INGRESS_SERVICE ingress-nginx/ingress-nginx \
  --namespace $NGINX_INGRESS_NAMESPACE \
  --create-namespace \
  --set controller.replicaCount=2 \
  --set controller.nodeSelector."kubernetes\.io/os"=linux \
  --set controller.admissionWebhooks.patch.nodeSelector."kubernetes\.io/os"=linux \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
  --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
  -f ./manifests/internal-ingress-green.yaml

# wait for the nginx controller to come up
sleep 30s

# Create a namespace
kubectl create ns $APP_NAMESPACE

# Deploy the application
envsubst < ./manifests/colourserver.yaml | kubectl -n $APP_NAMESPACE apply -f  -

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
spec:
  ingressClassName: nginx
  rules:
  - host: aks.test.internal
    http:
      paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: colour
              port:
                number: 80
EOF
