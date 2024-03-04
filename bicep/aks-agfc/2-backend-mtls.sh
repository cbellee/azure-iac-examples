#########################
# backend mTLS 
#########################

LOCATION="australiaeast"
AKS_NAME="aks-agc"
RESOURCE_GROUP="$AKS_NAME-rg"
ALB_NAME='alb-agfc'
ALB_NAMESPACE='agfc'

az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME --admin

# apply app deployment
kubectl apply -f ./backend-mtls/deployment.yaml # https://trafficcontrollerdocs.blob.core.windows.net/examples/https-scenario/end-to-end-ssl-with-backend-mtls/deployment.yaml

# create gateway Object
kubectl apply -f ./backend-mtls/gateway.yaml

# verify gateway
kubectl get gateway gateway-01 -n backend-mtls -o yaml

# create HTTP route
kubectl apply -f ./backend-mtls/http-route.yaml

# verify route
kubectl get httproute -n backend-mtls https-route -o yaml

# create backend TLS policy
kubectl apply -f ./backend-mtls/backend-tls-policy.yaml

# verify TLS policy
kubectl get backendtlspolicy -n backend-mtls mtls-app-tls-policy -o yaml

# test
fqdn=$(kubectl get gateway gateway-01 -n backend-mtls -o jsonpath='{.status.addresses[0].value}')
curl --insecure https://$fqdn/ -vk
