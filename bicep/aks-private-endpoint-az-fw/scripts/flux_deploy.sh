location='australiaeast'
prefix='aks-private-azfw'
deploymentName='infra-deployment'
rgName="${prefix}-rg"

# get the AKS cluster name
clusterName=$(az deployment group show \
    -g $rgName \
    -n 'infra-deployment' \
    --query 'properties.outputs.aksClusterName.value' -o tsv)

acrName=$(az deployment group show \
    -g $rgName \
    -n 'module-acr' \
    --query 'properties.outputs.registryName.value' -o tsv)

echo "clusterName: ${clusterName}"
echo "acrName: ${acrName}"

# add required providers
az provider register --namespace Microsoft.OperationsManagement
az provider register --namespace Microsoft.OperationalInsights
az feature register --name EnablePodIdentityPreview --namespace Microsoft.ContainerService
az feature register --namespace Microsoft.ContainerService --name AKS-AzureKeyVaultSecretsProvider
az provider register --namespace Microsoft.ContainerService

# add required extensions
az extension add -n k8s-configuration
az extension add -n k8s-extension

# attach acr to aks
az aks update -n $clusterName -g $rgName --attach-acr $acrName

# create flux config
az k8s-configuration flux create \
    --name gitops-demo \
    --resource-group $rgName \
    --cluster-name $clusterName \
    --namespace gitops-demo \
    --cluster-type managedClusters \
    --scope cluster \
    -u git@github.com:cbellee/flux2-kustomize-helm-example \
    --ssh-private-key-file ~/.ssh/id_rsa \
    --branch main \
    --kustomization name=infra path=./infrastructure prune=true \
    --kustomization name=apps path=./apps/staging prune=true depends_on=["infra"]

# delete flux config
# az k8s-extension delete \
  # --resource-group $rgName \
  # --cluster-name $clusterName \
  # --namespace flux \
  # --cluster-type managedClusters \
  # --yes
