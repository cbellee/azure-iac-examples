LOCATION='australiaeast'
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
LATEST_K8S_VERSION=$(az aks get-versions -l $LOCATION | jq -r -c '[.orchestrators[] | .orchestratorVersion][-1]')
PREFIX='aks-kuma-service-mesh'
RG_NAME="$PREFIX-rg"
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)

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

# download & install kuma


# install kuma
kumactl install control-plane | kubectl apply -f -

kubectl get meshes

# enable mTLS for the mesh
echo "apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabledBackend: ca-1
    backends:
    - name: ca-1
      type: builtin" | kubectl apply -f -

# clone demo repo
git clone https://github.com/kumahq/kuma-counter-demo.git

# deploy demo app
kubectl apply -f ./kuma-counter-demo/demo.yaml

# port forward to demo app
kubectl port-forward svc/demo-app -n kuma-demo 5000:5000

# deploy demo app v2
kubectl apply -f ./kuma-counter-demo/demo-v2.yaml

# port forward to kuma GUI
kubectl port-forward svc/kuma-control-plane -n kuma-system 5681:5681

# remove default allow-all permission
kubectl delete trafficpermission allow-all-default

# add default allow-all permission
echo "apiVersion: kuma.io/v1alpha1
kind: TrafficPermission
mesh: default
metadata:
  name: allow-all-default
spec:
  sources:
    - match:
        kuma.io/service: '*'
  destinations:
    - match:
        kuma.io/service: '*'" | kubectl apply -f -

# install observability components
kumactl install observability | kubectl apply -f -

# enable prometheus metrics
echo "apiVersion: kuma.io/v1alpha1
kind: Mesh
metadata:
  name: default
spec:
  mtls:
    enabledBackend: ca-1
    backends:
    - name: ca-1
      type: builtin
  metrics:
    enabledBackend: prometheus-1
    backends:
    - name: prometheus-1
      type: prometheus" | kubectl apply -f -

# port forward to Grafana service
kubectl port-forward svc/grafana -n mesh-observability 3000:80
