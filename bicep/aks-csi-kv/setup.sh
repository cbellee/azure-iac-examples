RG_NAME=aks-csi-rg
CLUSTER_NAME=aks-csi
export DEV_KV=dev-j6yiv4bnl3duy
export UAT_KV=uat-j6yiv4bnl3duy

# install yq to replace yaml file values
# wget https://github.com/mikefarah/yq/releases/download/v4.25.3/yq_linux_arm64
# cp ./yq_linux_arm64 /usr/local/bin/yq

# create namespaces
k create ns dev
k create ns uat

# enable the 'azure keyvault secrets provider' addon
az aks enable-addons --addons azure-keyvault-secrets-provider --name $CLUSTER_NAME --resource-group $RG_NAME

# get the AKS node pools (VMSS)
export TENANT_ID=$(az account show --query tenantId -o tsv)
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

yq e '(.metadata.name = "azure-dev-msi") | (.metadata.namespace = "dev") | (.spec.parameters.tenantId = strenv(TENANT_ID)) | (.spec.parameters.userAssignedIdentityID = strenv(DEV_APPID)) | (.spec.parameters.keyvaultName = strenv(DEV_KV))' ./manifests/secret-provider-template.yaml > ./manifests/dev-secret-provider.yaml
yq e '(.metadata.name = "azure-uat-msi") | (.metadata.namespace = "uat") | (.spec.parameters.tenantId = strenv(TENANT_ID)) | (.spec.parameters.userAssignedIdentityID = strenv(UAT_APPID)) | (.spec.parameters.keyvaultName = strenv(UAT_KV))' ./manifests/secret-provider-template.yaml > ./manifests/uat-secret-provider.yaml

yq e '(.metadata.name = "busybox-dev-user-msi") | (.metadata.namespace = "dev") | (.spec.volumes[0].csi.volumeAttributes.secretProviderClass = "azure-dev-msi")' ./manifests/pod-template.yaml > ./manifests/dev-pod.yaml
yq e '(.metadata.name = "busybox-uat-user-msi") | (.metadata.namespace = "uat") | (.spec.volumes[0].csi.volumeAttributes.secretProviderClass = "azure-uat-msi")' ./manifests/pod-template.yaml > ./manifests/uat-pod.yaml

k apply -f ./manifests/dev-secret-provider.yaml
k apply -f ./manifests/uat-secret-provider.yaml
k apply -f ./manifests/dev-pod.yaml
k apply -f ./manifests/uat-pod.yaml

# exec into 'dev' container
k exec -it busybox-dev-user-msi -n dev -c busybox /bin/sh

# run cmd within pod to print secret
 cat /mnt/secrets-store/my-secret 
# this secret is from 'dev' key vault

# exec into 'uat' container
k exec -it busybox-uat-user-msi -n dev -c busybox /bin/sh

# run cmd within pod to print secret
cat /mnt/secrets-store/my-secret 
# this secret is from 'uat' key vault