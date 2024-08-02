LOCATION='australiaeast'
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
ADMIN_GROUP_OBJECT_ID="9a9ebfda-180c-4957-b9ce-2e2fbfbd2a0f"
RG_NAME="aks-basic-rg"
AKS_VERSION=$(az aks get-versions -l australiaeast | jq .values[0].version -r)

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
    --parameters isIstioEnabled=false \
    --parameters adminGroupObjectID=$ADMIN_GROUP_OBJECT_ID

CLUSTER_NAME=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.aksClusterName.value' -o tsv)

az aks get-credentials -g $RG_NAME -n $CLUSTER_NAME --admin --context 'aks-basic' --overwrite-existing

# update helm repo
helm repo add azure-samples https://azure-samples.github.io/helm-charts
helm repo add nginx-ingress https://kubernetes.github.io/ingress-nginx

# deploy apps
helm install azure-vote azure-samples/azure-vote --set serviceType=ClusterIP
helm upgrade -i my-release oci://ghcr.io/stefanprodan/charts/podinfo

# deploy ingress controller
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --create-namespace \
  --namespace nginx-ingress \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz

# deploy ingress definition
kubectl apply -f - << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  ingressClassName: nginx
  rules:
  - host: azure-vote.apps.kainiindustries.net
    http:
      paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: azure-vote-front
              port:
                number: 80
  - host: podinfo.apps.kainiindustries.net
    http:
      paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: my-release-podinfo
              port:
                number: 9898
EOF

# add the following DNS records to your owned Domain
# A: apps.<domain> -> <Ingress Controller Public IP>
# CNAME: podinfo.apps -> apps.<domain>
# CNAME: azure-vote.apps -> apps.<domain>

# test ingress
curl http://podinfo.apps.kainiindustries.net
curl http://azure-vote.apps.kainiindustries.net

:'

install istio
get binary
cd ./istio-1.19.3
sudo cp ./istioctl /home/cbellee/.local/bin/
curl -L https://istio.io/downloadIstio | sh -

istioctl install -f ./istio/values.yml
# remove finalizer prevents ALB from deletion when Istio is uninstalled
kubectl patch service istio-ingressgateway -n istio-system -p '{"metadata":{"finalizers":[]}}' --type=merge

label default namespace
kubectl label namespace default istio-injection=enabled

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
'

INGRESS_VIP=`kubectl get ingress azure-vote-ingress  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'`

az network dns record-set a delete -g $DNS_RG -z $DOMAIN -n $RECORD_NAME
az network dns record-set a add-record -g $DNS_RG -z $DOMAIN -n $RECORD_NAME -a $INGRESS_VIP --ttl 300
