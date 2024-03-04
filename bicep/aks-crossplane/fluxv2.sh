STAGING_RG_NAME='aks-staging-rg'
PRODUCTION_RG_NAME='aks-production-rg'
NAMESPACE='gitops-demo'
STAGING_CLUSTER_NAME=$(az deployment group show --resource-group $STAGING_RG_NAME --name aks-deployment --query 'properties.outputs.aksClusterName.value' -o tsv)
PRODUCTION_CLUSTER_NAME=$(az deployment group show --resource-group $PRODUCTION_RG_NAME --name aks-deployment --query 'properties.outputs.aksClusterName.value' -o tsv)

# register namspaces
az feature register --namespace Microsoft.ContainerService --name AKS-ExtensionManager
az version
az upgrade

az provider register --namespace Microsoft.Kubernetes
az provider register --namespace Microsoft.ContainerService
az provider register --namespace Microsoft.KubernetesConfiguration

az provider show -n Microsoft.KubernetesConfiguration -o table

# enable cli extensions
az extension add -n k8s-configuration
az extension add -n k8s-extension

az extension update -n k8s-configuration
az extension update -n k8s-extension

az extension list -o table

# list kubectl contexts
kubectl config get-contexts

############## 
# STAGING
##############

# NOTE: this is now defind in the bicep template
# apply flux configuration to staging cluster
az k8s-configuration flux create \
    --resource-group $STAGING_RG_NAME \
    --cluster-name $STAGING_CLUSTER_NAME \
    --name $NAMESPACE \
    --namespace $NAMESPACE \
    --cluster-type managedClusters \
    --scope cluster \
    --url https://github.com/cbellee/flux2-kustomize-helm-example \
    --branch main \
    --kustomization name=infra path=./infrastructure prune=true \
    --kustomization name=apps path=./apps/staging prune=true depends_on=infra

# show flux configuration for staging cluster
az k8s-configuration flux show -g $STAGING_RG_NAME -c $STAGING_CLUSTER_NAME -n $NAMESPACE -t managedClusters

# change scope to staging cluster
kubectl config use-context aks-staging-admin

# list namespaces
kubectl get ns

# list flux pods
kubectl get pods -n flux-system

# list crds
kubectl get crds

# list fluxconfigs
kubectl get fluxconfigs -A

# list gitrepositories
kubectl get gitrepositories -A

# list helmreleases
kubectl get helmreleases -A

# list kustomizations
kubectl get kustomizations -A

# get deployments
kubectl get deploy -n nginx
kubectl get deploy -n podinfo
kubectl get all -n redis

############## 
# PRODUCTION
##############

# NOTE: this is now defind in the bicep template
# apply flux configuration to production cluster
#az k8s-configuration flux create \
#    --resource-group $PRODUCTION_RG_NAME \
#    --cluster-name $PRODUCTION_CLUSTER_NAME \
#    --name $NAMESPACE \
#    --namespace $NAMESPACE \
#    --cluster-type managedClusters \
#    --scope cluster \
#    --url https://github.com/cbellee/flux2-kustomize-helm-example \
#    --branch main \
#    --kustomization name=infra path=./infrastructure prune=true \
#    --kustomization name=apps path=./apps/production prune=true depends_on=infra

# show flux configuration for production cluster
az k8s-configuration flux show -g $PRODUCTION_RG_NAME -c $PRODUCTION_CLUSTER_NAME -n $NAMESPACE -t managedClusters

# change scope to production cluster
kubectl config use-context aks-production-admin

# list namespaces
kubectl get ns

# list flux pods
kubectl get pods -n flux-system

# list crds
kubectl get crds

# list fluxconfigs
kubectl get fluxconfigs -A

# list gitrepositories
kubectl get gitrepositories -A

# list helmreleases
kubectl get helmreleases -A

# list kustomizations
kubectl get kustomizations -A

# get deployments
kubectl get deploy -n nginx
kubectl get deploy -n podinfo
kubectl get all -n redis

# delete fluxconfiguration
# az k8s-configuration flux delete -g flux-demo-rg -c flux-demo-arc -n gitops-demo -t connectedClusters --yes

# delete flux extension
# az k8s-extension delete -g flux-demo-rg -c flux-demo-arc -n flux -t connectedClusters --yes
