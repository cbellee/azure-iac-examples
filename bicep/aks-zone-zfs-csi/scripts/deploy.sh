CLUSTER_NAME='aks-zone-zfs-test'
RG_NAME="$CLUSTER_NAME-rg"
NAMESPACE='zfs-pv-test'

az aks get-credentials --name $CLUSTER_NAME --resource-group $RG_NAME

k create ns $NAMESPACE
kubectl apply -f ../manifests/pvc-azuredisk-csi.yaml -n $NAMESPACE
kubectl apply -f ../manifests/nginx-pod-azuredisk.yaml -n $NAMESPACE
