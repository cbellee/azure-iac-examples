while getopts r:c: option; do
    case "${option}" in

    r) AKS_RESOURCE_GROUP_NAME=${OPTARG} ;;
    c) AKS_CLUSTER_NAME=${OPTARG} ;;
    esac
done

# get aks credentials
az aks get-credentials -g $AKS_RESOURCE_GROUP_NAME -n $AKS_CLUSTER_NAME

# install pod identity service
kubectl create -f https://raw.githubusercontent.com/Azure/aad-pod-identity/master/deploy/infra/deployment-rbac.yaml

# install helm 3 (2.19+)
#kubectl create serviceaccount --namespace kube-system tiller-sa
#kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller-sa
#helm init --tiller-namespace kube-system --service-account tiller-sa --wait --upgrade
helm repo add application-gateway-kubernetes-ingress https://appgwingress.blob.core.windows.net/ingress-azure-helm-package/
helm repo update

# deploy Application Gateway ingress controller
helm upgrade --install agic -f helm-config.yaml application-gateway-kubernetes-ingress/ingress-azure --set appgw.usePrivateIP=false
