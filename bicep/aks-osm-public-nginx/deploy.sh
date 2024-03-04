LOCATION='australiaeast'
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
LATEST_K8S_VERSION=$(az aks get-versions -l $LOCATION | jq -r -c '[.orchestrators[] | .orchestratorVersion][-1]')
PREFIX='aks-osm-public-nginx'
RG_NAME="$PREFIX-rg"
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
DOMAIN_NAME='kainiindustries.net'

PUBLIC_PFX_CERT_FILE="./certs/star.$DOMAIN_NAME.bundle.pfx"
PUBLIC_PFX_CERT_NAME='public-certificate-pfx'
PUBLIC_CERT_NAME='tls-cert'

NGINX_INGRESS_NAMESPACE='ingress-nginx-osm'
NGINX_INGRESS_SERVICE='ingress-nginx'
OSM_NAMESPACE='kube-system'
OSM_MESH_NAME='osm'
NGINX_CLIENT_CERT_NAME='osm-nginx-client-cert'
APP_NAMESPACE='myapps'

source ./.env

# create resource group
az group create --location $LOCATION --name $RG_NAME

# deploy infrastructure
az deployment group create \
  --resource-group $RG_NAME \
  --name infra-deployment \
  --template-file ./main.bicep \
  --parameters @main.parameters.json \
  --parameters location=$LOCATION \
  --parameters sshPublicKey="$SSH_KEY" \
  --parameters adminGroupObjectID=$ADMIN_GROUP_OBJECT_ID \
  --parameters k8sVersion=$LATEST_K8S_VERSION \
  --parameters dnsPrefix=$PREFIX

CLUSTER_NAME=$(az deployment group show --resource-group $RG_NAME --name infra-deployment --query 'properties.outputs.aksClusterName.value' -o tsv)
az aks get-credentials -g $RG_NAME -n $CLUSTER_NAME --admin

###################
# install NGINX 
###################

# Add the ingress-nginx repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx

# Use Helm to deploy an NGINX ingress controller
helm install $NGINX_INGRESS_SERVICE ingress-nginx/ingress-nginx \
  --version 4.3.0 \
  --namespace $NGINX_INGRESS_NAMESPACE \
  --create-namespace \
  --set controller.replicaCount=2 \
  --set controller.nodeSelector."kubernetes\.io/os"=linux \
  --set controller.admissionWebhooks.patch.nodeSelector."kubernetes\.io/os"=linux \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
  --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux
  
####################
# Configure OSM
####################

# disable sidecar injection for the NGINX controller pods
osm namespace add $NGINX_INGRESS_NAMESPACE --mesh-name $OSM_MESH_NAME --disable-sidecar-injection

# Create app namespace
kubectl create ns $APP_NAMESPACE

# Add the namespace to the mesh
osm namespace add $APP_NAMESPACE

# create 2 deployments (httpbin & podinfo)
kubectl apply -f ./manifests/httpbin.yaml -n $APP_NAMESPACE 
kubectl apply -f ./manifests/podinfo.yaml -n $APP_NAMESPACE

# create k8s secret from .pfx bundle
openssl pkcs12 -in ./certs/star.kainiindustries.net.bundle.pfx -out ./certs/star.kainiindustries.net.bundle.pem -nodes
openssl pkey -in ./certs/star.kainiindustries.net.bundle.pem -out ./certs/star.kainiindustries.net.key
openssl crl2pkcs7 -nocrl -certfile ./certs/star.kainiindustries.net.bundle.pem | openssl pkcs7 -print_certs -out ./certs/star.kainiindustries.net.bundle.crt

kubectl create secret tls $PUBLIC_CERT_NAME --namespace $APP_NAMESPACE --key ./certs/star.kainiindustries.net.bundle.pem --cert ./certs/star.kainiindustries.net.bundle.crt

# configure OSM to generate a client certificate for NGINX to use when connecting to the mesh
kubectl get meshconfig osm-mesh-config -n $OSM_NAMESPACE -o json | 
jq --arg clientCertName "$NGINX_CLIENT_CERT_NAME" \
--arg osmNamespace "$OSM_NAMESPACE" \
--arg nginxName "$NGINX_INGRESS_SERVICE.$NGINX_INGRESS_NAMESPACE.cluster.local" '.spec.certificate += {"ingressGateway": {"secret": {"name": $clientCertName,"namespace": $osmNamespace},"subjectAltNames": [$nginxName],"validityDuration": "24h"}}' |
kubectl apply -f -

#############################################
# Deploy Ingress & IngressBackend manifests
#############################################

# wait for the nginx controller to come up
sleep 60s

# apply manifests
kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: httpbin
  namespace: $APP_NAMESPACE
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    # proxy_ssl_name for a service is of the form <service-account>.<namespace>.cluster.local
    nginx.ingress.kubernetes.io/configuration-snippet: | 
      proxy_ssl_name "httpbin.$APP_NAMESPACE.cluster.local";
    nginx.ingress.kubernetes.io/proxy-ssl-secret: "$OSM_NAMESPACE/$NGINX_CLIENT_CERT_NAME"
    nginx.ingress.kubernetes.io/proxy-ssl-verify: "on"
    nginx.ingress.kubernetes.io/rewrite-target: "/"
spec:
  tls:
  - hosts:
    - "osmtest.$DOMAIN_NAME"
    secretName: $PUBLIC_CERT_NAME
  ingressClassName: nginx
  rules:
  - host: "osmtest.$DOMAIN_NAME"
    http:
      paths:
      - path: "/"
        pathType: Prefix
        backend:
          service:
            name: httpbin
            port:
              number: 14001
---
apiVersion: policy.openservicemesh.io/v1alpha1
kind: IngressBackend
metadata:
  name: httpbin
  namespace: $APP_NAMESPACE
spec:
  backends:
  - name: httpbin
    port:
      number: 14001 # targetPort of httpbin service
      protocol: https
    tls:
      skipClientCertValidation: false
  sources:
  - kind: Service
    name: "$NGINX_INGRESS_SERVICE-controller"
    namespace: $NGINX_INGRESS_NAMESPACE
  - kind: AuthenticatedPrincipal
    name: $NGINX_INGRESS_SERVICE.$NGINX_INGRESS_NAMESPACE.cluster.local
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: podinfo
  namespace: $APP_NAMESPACE
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
    # proxy_ssl_name for a service is of the form <service-account>.<namespace>.cluster.local
    nginx.ingress.kubernetes.io/configuration-snippet: | 
      proxy_ssl_name "podinfo.$APP_NAMESPACE.cluster.local";
    nginx.ingress.kubernetes.io/proxy-ssl-secret: "$OSM_NAMESPACE/$NGINX_CLIENT_CERT_NAME"
    nginx.ingress.kubernetes.io/proxy-ssl-verify: "on"
    nginx.ingress.kubernetes.io/rewrite-target: "/"
spec:
  tls:
  - hosts:
    - "osmtest.$DOMAIN_NAME"
    secretName: $PUBLIC_CERT_NAME
  ingressClassName: nginx
  rules:
  - host: "osmtest.$DOMAIN_NAME"
    http:
      paths:
      - path: "/podinfo"
        pathType: Prefix
        backend:
          service:
            name: podinfo
            port:
              number: 9898
---
apiVersion: policy.openservicemesh.io/v1alpha1
kind: IngressBackend
metadata:
  name: podinfo
  namespace: $APP_NAMESPACE
spec:
  backends:
  - name: podinfo
    port:
      number: 9898 # targetPort of podinfo service
      protocol: https
    tls:
      skipClientCertValidation: false
  sources:
  - kind: Service
    name: "$NGINX_INGRESS_SERVICE-controller"
    namespace: $NGINX_INGRESS_NAMESPACE
  - kind: AuthenticatedPrincipal
    name: $NGINX_INGRESS_SERVICE.$NGINX_INGRESS_NAMESPACE.cluster.local
EOF

# wait for the Ingress change to apply
sleep 15s

# test the connection 
curl "https://httpbin.$DOMAIN_NAME"
curl "https://httpbin.$DOMAIN_NAME/v2"
