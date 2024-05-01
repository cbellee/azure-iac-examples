az extension add --name fleet

export GROUP='aks-fleet-demo-rg'
export FLEET='my-fleet'
export LOCATION_1='australiaeast'
export LOCATION_2='australiasoutheast'

# create resource group
az group create --name ${GROUP} --location ${LOCATION_1}

# create fleet
az fleet create --resource-group ${GROUP} --name ${FLEET} --location ${LOCATION_1} --enable-hub

# create aue vnet
az network vnet create --name vnet-aue --resource-group ${GROUP} --location ${LOCATION_1} --address-prefixes 10.100.0.0/16
AUE_DEV_SUBNET_ID=$(az network vnet subnet create --name dev-subnet --vnet-name vnet-aue --resource-group ${GROUP} --address-prefixes 10.100.1.0/24 --query id -o tsv)
AUE_TEST_SUBNET_ID=$(az network vnet subnet create --name test-subnet --vnet-name vnet-aue --resource-group ${GROUP} --address-prefixes 10.100.2.0/24 --query id -o tsv)
AUE_PROD_SUBNET_ID=$(az network vnet subnet create --name prod-subnet --vnet-name vnet-aue --resource-group ${GROUP} --address-prefixes 10.100.3.0/24 --query id -o tsv)

# create ause vnet
az network vnet create --name vnet-ause --resource-group ${GROUP} --location ${LOCATION_2} --address-prefixes 10.200.0.0/16
AUSE_DEV_SUBNET_ID=$(az network vnet subnet create --name dev-subnet --vnet-name vnet-ause --resource-group ${GROUP} --address-prefixes 10.200.1.0/24 --query id -o tsv)
AUSE_TEST_SUBNET_ID=$(az network vnet subnet create --name test-subnet --vnet-name vnet-ause --resource-group ${GROUP} --address-prefixes 10.200.2.0/24 --query id -o tsv)
AUSE_PROD_SUBNET_ID=$(az network vnet subnet create --name prod-subnet --vnet-name vnet-ause --resource-group ${GROUP} --address-prefixes 10.200.3.0/24 --query id -o tsv)

# peer the vnets
az network vnet peering create --name aue-to-ause --resource-group ${GROUP} --vnet-name vnet-aue --remote-vnet vnet-ause --allow-vnet-access --allow-forwarded-traffic
az network vnet peering create --name ause-to-aue --resource-group ${GROUP} --vnet-name vnet-ause --remote-vnet vnet-aue --allow-vnet-access --allow-forwarded-traffic

# create AKS clusters
az aks create -g ${GROUP} -n aue-dev-cluster-1 -k 1.29.2 --ssh-key-value ~/.ssh/id_rsa.pub --location ${LOCATION_1} --network-plugin azure --vnet-subnet-id $AUE_DEV_SUBNET_ID --no-wait
az aks create -g ${GROUP} -n ause-dev-cluster-2 -k 1.29.0 --ssh-key-value ~/.ssh/id_rsa.pub --location ${LOCATION_2} --network-plugin azure --vnet-subnet-id $AUSE_DEV_SUBNET_ID --no-wait
az aks create -g ${GROUP} -n aue-test-cluster-1 -k 1.28.5 --ssh-key-value ~/.ssh/id_rsa.pub --location ${LOCATION_1} --network-plugin azure --vnet-subnet-id $AUE_TEST_SUBNET_ID --no-wait
az aks create -g ${GROUP} -n ause-test-cluster-2 -k 1.28.5 --ssh-key-value ~/.ssh/id_rsa.pub --location ${LOCATION_2} --network-plugin azure --vnet-subnet-id $AUSE_TEST_SUBNET_ID --no-wait

CLUSTER_1_ID=$(az aks show -g ${GROUP} -n aue-dev-cluster-1 --query id -o tsv)
CLUSTER_2_ID=$(az aks show -g ${GROUP} -n ause-dev-cluster-2 --query id -o tsv)
CLUSTER_3_ID=$(az aks show -g ${GROUP} -n aue-test-cluster-1 --query id -o tsv)
CLUSTER_4_ID=$(az aks show -g ${GROUP} -n ause-test-cluster-2 --query id -o tsv)

# join the member clusters to the fleet 
az fleet member create --resource-group ${GROUP} --fleet-name ${FLEET} --name dev-aks-1 --member-cluster-id ${CLUSTER_1_ID} --update-group dev --nodepool-labels env=dev location=syd --no-wait
az fleet member create --resource-group ${GROUP} --fleet-name ${FLEET} --name dev-aks-2 --member-cluster-id ${CLUSTER_2_ID} --update-group dev --nodepool-labels env=dev location=mel --no-wait
az fleet member create --resource-group ${GROUP} --fleet-name ${FLEET} --name test-aks-1 --member-cluster-id ${CLUSTER_3_ID} --update-group test --nodepool-labels env=dev location=syd --no-wait
az fleet member create --resource-group ${GROUP} --fleet-name ${FLEET} --name test-aks-2 --member-cluster-id ${CLUSTER_4_ID} --update-group test --nodepool-labels env=dev location=mel --no-wait

# get fleet hub cluster creds
az fleet get-credentials --resource-group ${GROUP} --name ${FLEET} --file fleet
az aks get-credentials --resource-group ${GROUP} --name aue-dev-cluster-1 --file dev-cluster-1-aue
az aks get-credentials --resource-group ${GROUP} --name ause-dev-cluster-2 --file dev-cluster-2-ause
az aks get-credentials --resource-group ${GROUP} --name aue-test-cluster-1 --file test-cluster-1-aue
az aks get-credentials --resource-group ${GROUP} --name ause-test-cluster-2 --file test-cluster-2-ause

##############
# Demos
##############

# 1 - Deploy 'kuard-demo' application to multiple clusters in a fleet

# create namespace
KUBECONFIG=fleet kubectl create namespace kuard-demo
# KUBECONFIG=fleet kubectl delete namespace kuard-demo

KUBECONFIG=fleet kubectl get ns -A

# deploy application
KUBECONFIG=fleet kubectl apply -f ./manifests/kuard/kuard-export-service.yaml

# list deployment & load balancer service
# note that no pods are created on the hub cluster & external IP is in 'pending' state
KUBECONFIG=fleet kubectl get all -n kuard-demo

# place application to clusters defind in the 'kuard-crp-dev.yaml' file
KUBECONFIG=fleet kubectl apply -f ./manifests/kuard/kuard-crp-dev.yaml
# KUBECONFIG=fleet kubectl delete clusterresourceplacements kuard-demo

# verify the namespace and deployment was created on all member clusters
KUBECONFIG=fleet kubectl get clusterresourceplacements

# verify the application was deployed to all member clusters in australiaeast region
KUBECONFIG=dev-cluster-1-aue kubectl get all -n kuard-demo
KUBECONFIG=dev-cluster-2-ause kubectl get all -n kuard-demo

# verify the application was NOT deployed to 'tet' environent member clusters
KUBECONFIG=test-cluster-1-aue kubectl get all -n kuard-demo
KUBECONFIG=test-cluster-2-ause kubectl get all -n kuard-demo


# verify load balancer service was exported
KUBECONFIG=dev-cluster-1-aue kubectl get serviceexport kuard --namespace kuard-demo
KUBECONFIG=dev-cluster-2-ause kubectl get serviceexport kuard --namespace kuard-demo

# create a multi-cluster service
KUBECONFIG=dev-cluster-1-aue kubectl apply -f ./manifests/kuard/kuard-mcs.yaml
KUBECONFIG=dev-cluster-2-ause kubectl get multiclusterservice kuard --namespace kuard-demo
EXTERNAL_IP=$(KUBECONFIG=dev-cluster-1-aue kubectl get multiclusterservice kuard --namespace kuard-demo -o json | jq .status.loadBalancer.ingress[0].ip -r)

echo "http://${EXTERNAL_IP}:8080"
curl "${EXTERNAL_IP}:8080" | grep addrs

# start all clusters in the resource group
az aks list -g $GROUP -o json | jq .[].name -r | while read cluster; do
    az aks start -n $cluster -g ${GROUP} --no-wait
done
