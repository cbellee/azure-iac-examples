LOCATION='australiaeast'
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
export TENANT_ID=$(az account show --query tenantId -o tsv)
ADMIN_GROUP_OBJECT_ID="f6a900e2-df11-43e7-ba3e-22be99d3cede"
LATEST_K8S_VERSION_IN_REGION=$(az aks get-versions -l $LOCATION | jq -r -c '[.orchestrators[] | .orchestratorVersion][-1]')
PREFIX=csidriver
export RG_NAME="aks-${PREFIX}-rg"

# download & install yq to replace yaml template file values
# wget https://github.com/mikefarah/yq/releases/download/v4.25.3/yq_linux_arm64
# cp ./yq_linux_arm64 /usr/local/bin/yq

az group create --location $LOCATION --name $RG_NAME

az deployment group create \
    --resource-group $RG_NAME \
    --name aks-deployment \
    --template-file ./main.bicep \
    --parameters @main.parameters.json \
    --parameters prefix=$PREFIX \
    --parameters sshPublicKey="$SSH_KEY" \
    --parameters adminGroupObjectID=$ADMIN_GROUP_OBJECT_ID \
    --parameters aksVersion=$LATEST_K8S_VERSION_IN_REGION

CLUSTER_NAME=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.aksClusterName.value' -o tsv)

az aks get-credentials -g $RG_NAME -n $CLUSTER_NAME --admin

#########################################
# install CSI driver & configure 
# User Managed Identities & test pods
#########################################

export DEV_KV=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query properties.outputs.devKeyVaultName.value -o tsv)
export UAT_KV=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query properties.outputs.uatKeyVaultName.value -o tsv)

# create namespaces
kubectl create ns dev
kubectl create ns uat

# enable the 'azure keyvault secrets provider' addon
az aks enable-addons --addons azure-keyvault-secrets-provider --name $CLUSTER_NAME --resource-group $RG_NAME

# get the AKS node pools (VMSS)
NODE_RESOURCE_GROUP=$(az aks show -g $RG_NAME --name $CLUSTER_NAME --query nodeResourceGroup -o tsv)
USER_VMSS=$(az vmss list -g $NODE_RESOURCE_GROUP --query '[].name | [0]' -o tsv)
SYSTEM_VMSS=$(az vmss list -g $NODE_RESOURCE_GROUP --query '[].name | [1]' -o tsv)

# create User Managed Identities for each keyvault and assign to each AKS VMSS (nodepool)
DEV_UMID=$(az identity create -g $RG_NAME -n 'dev-kv-umid' --query id -o tsv)
UAT_UMID=$(az identity create -g $RG_NAME -n 'uat-kv-umid' --query id -o tsv)

az vmss identity assign -g $NODE_RESOURCE_GROUP -n $USER_VMSS --identities $DEV_UMID
az vmss identity assign -g $NODE_RESOURCE_GROUP -n $SYSTEM_VMSS --identities $DEV_UMID

az vmss identity assign -g $NODE_RESOURCE_GROUP -n $USER_VMSS --identities $UAT_UMID
az vmss identity assign -g $NODE_RESOURCE_GROUP -n $SYSTEM_VMSS --identities $UAT_UMID

# update VMSS instances
az vmss update-instances -g $NODE_RESOURCE_GROUP -n $USER_VMSS --instance-ids "*"
az vmss update-instances -g $NODE_RESOURCE_GROUP -n $SYSTEM_VMSS --instance-ids "*"

# set keyvault access policy to access to keyvault secrets
export DEV_APPID=$(az identity show -g $RG_NAME -n 'dev-kv-umid' --query clientId -o tsv)
az keyvault set-policy -n $DEV_KV --secret-permissions get --spn $DEV_APPID
az keyvault set-policy -n $DEV_KV --secret-permissions all --object-id $(az ad signed-in-user show --query objectId -o tsv)

export UAT_APPID=$(az identity show -g $RG_NAME -n 'uat-kv-umid' --query clientId -o tsv)
az keyvault set-policy -n $UAT_KV --secret-permissions get --spn $UAT_APPID
az keyvault set-policy -n $UAT_KV --secret-permissions all --object-id $(az ad signed-in-user show --query objectId -o tsv)

# add secrets to the keyvaults
az keyvault secret set --vault-name $DEV_KV --name my-secret --value "this secret is from 'dev' key vault"
az keyvault secret set --vault-name $UAT_KV --name my-secret --value "this secret is from 'uat' key vault" 

# create dev-secret-provider.yaml & uat-secret-provider.yaml manifests
yq e '(.metadata.name = "azure-dev-msi") | (.metadata.namespace = "dev") | (.spec.parameters.tenantId = strenv(TENANT_ID)) | (.spec.parameters.userAssignedIdentityID = strenv(DEV_APPID)) | (.spec.parameters.keyvaultName = strenv(DEV_KV))' ./manifests/secret-provider-template.yaml > ./manifests/dev-secret-provider.yaml
yq e '(.metadata.name = "azure-uat-msi") | (.metadata.namespace = "uat") | (.spec.parameters.tenantId = strenv(TENANT_ID)) | (.spec.parameters.userAssignedIdentityID = strenv(UAT_APPID)) | (.spec.parameters.keyvaultName = strenv(UAT_KV))' ./manifests/secret-provider-template.yaml > ./manifests/uat-secret-provider.yaml

# create dev-spod.yaml & uat-pod.yaml manifests
yq e '(.metadata.name = "busybox-dev-user-msi") | (.metadata.namespace = "dev") | (.spec.volumes[0].csi.volumeAttributes.secretProviderClass = "azure-dev-msi")' ./manifests/pod-template.yaml > ./manifests/dev-pod.yaml
yq e '(.metadata.name = "busybox-uat-user-msi") | (.metadata.namespace = "uat") | (.spec.volumes[0].csi.volumeAttributes.secretProviderClass = "azure-uat-msi")' ./manifests/pod-template.yaml > ./manifests/uat-pod.yaml

kubectl apply -f ./manifests/dev-secret-provider.yaml
kubectl apply -f ./manifests/uat-secret-provider.yaml
kubectl apply -f ./manifests/dev-pod.yaml
kubectl apply -f ./manifests/uat-pod.yaml

#### exec into 'dev' container
# kubectl exec -it busybox-dev-user-msi -n dev -c busybox /bin/sh

#### run cmd within dev-pod to print secret
# cat /mnt/secrets-store/my-secret 

#### exec into 'uat' container
# kubectl exec -it busybox-uat-user-msi -n uat -c busybox /bin/sh

# run cmd within uat-pod to print secret
# cat /mnt/secrets-store/my-secret 
