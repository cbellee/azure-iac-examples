LOCATION='australiaeast'
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
ADMIN_GROUP_OBJECT_ID="f6a900e2-df11-43e7-ba3e-22be99d3cede"
RG_NAME="aks-basic-rg"
DNS_RG='external-dns-zones-rg'
DOMAIN='kainiindustries.net'
RECORD_NAME='azure-vote-front'
AKS_VERSION=$(az aks get-versions -l australiaeast | jq .values[0].version -r)
KEY_PATH='./certs/star_kainiindustries_net.key'
CERT_PATH='./certs/star_kainiindustries_net.crt'
ADMIN_GROUP_OBJECT_ID='c84cef69-ff8e-4906-82e1-c16f16081952'

az group create --location $LOCATION --name $RG_NAME

az deployment group create \
    --resource-group $RG_NAME \
    --name aks-deployment \
    --template-file ./main.bicep \
    --parameters @main.parameters.json \
    --parameters location=$LOCATION \
    --parameters sshPublicKey="$SSH_KEY" \
    --parameters aksVersion=$AKS_VERSION \
    --parameters dnsPrefix='aks-basic' \
    --parameters isIstioEnabled=true \
    --parameters adminGroupObjectID=$ADMIN_GROUP_OBJECT_ID

CLUSTER_NAME=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.aksClusterName.value' -o tsv)

az aks get-credentials -g $RG_NAME -n $CLUSTER_NAME --admin --context 'aks-basic' --overwrite-existing

# install istio
# get binary
# cd ./istio-1.19.3
# sudo cp ./istioctl /home/cbellee/.local/bin/
# curl -L https://istio.io/downloadIstio | sh -

istioctl install -f ./istio/values.yml

# remove finalizer prevents ALB from deletion when Istio is uninstalled
# kubectl patch service istio-ingressgateway -n istio-system -p '{"metadata":{"finalizers":[]}}' --type=merge

# label default namespace
kubectl label namespace default istio-injection=enabled

# install K8S objects
helm repo add azure-samples https://azure-samples.github.io/helm-charts/
helm repo add nginx-ingress https://kubernetes.github.io/ingress-nginx

helm install azure-vote azure-samples/azure-vote --set serviceType=ClusterIP

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --create-namespace \
  --namespace nginx-ingress \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz

kubectl create secret tls azure-vote-cert-secret --key $KEY_PATH --cert $CERT_PATH -n default

kubectl apply -f - << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: azure-vote-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  tls:
  - hosts:
    - "azure-vote-front.kainiindustries.net"
    secretName: azure-vote-cert-secret
  ingressClassName: nginx
  rules:
  - host: azure-vote-front.kainiindustries.net
    http:
      paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: azure-vote-front
              port:
                number: 80
EOF

INGRESS_VIP=`kubectl get ingress azure-vote-ingress  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'`

az network dns record-set a delete -g $DNS_RG -z $DOMAIN -n $RECORD_NAME
az network dns record-set a add-record -g $DNS_RG -z $DOMAIN -n $RECORD_NAME -a $INGRESS_VIP --ttl 300
