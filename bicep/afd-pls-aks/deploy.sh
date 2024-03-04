resourceGroupName='afd-pls-k8s-rg'
location='australiaeast'
deploymentName='myDeployment'

az group create -n $resourceGroupName -l $location

az deployment group create \
	--name $deploymentName \
	--resource-group $resourceGroupName \
	--template-file ./main.bicep \
	--mode Incremental \
	--parameters ./main.parameters.json \
	--what-if-result-format FullResourcePayloads

clusterName=$(az deployment group show -g $resourceGroupName -n $deploymentName --query properties.outputs.aks_cluster_name.value -o tsv)

az aks get-credentials -g $resourceGroupName -n $clusterName

# assign KeyVault CSI driver user managed identity 'Key Vault Administrator' role
export kvCsiIdentityClientId=$(az aks show -g $resourceGroupName -n clusterName --query addonProfiles.azureKeyvaultSecretsProvider.identity.clientId -o tsv)
export kvCsiIdentityResourceId=$(az aks show -g $resourceGroupName -n clusterName--query addonProfiles.azureKeyvaultSecretsProvider.identity.resourceId -o tsv)
export aksNodeResourceGroup=$(az aks show -g $resourceGroupName -n clusterName --query nodeResourceGroup -o tsv)

az role assignment create --role 'Key Vault Administrator' --assignee $kvCsiIdentityClientId --scope $KEYVAULT_SCOPE

# kubectl apply -f ./deploy.yml


# Add the ingress-nginx repository
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# install NGINX Ingress Controller
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --create-namespace \
  --namespace $NGINX_NAMESPACE \
  --set controller.replicaCount=2 \
  --set controller.nodeSelector."kubernetes\.io/os"=linux \
  --set defaultBackend.nodeSelector."kubernetes\.io/os"=linux \
  --set serviceAccount.annotations."azure\.workload\.identity/client-id"=$kvCsiIdentityClientId \
  -f - <<EOF
controller:
  service:
    annotations:
        annotations:
		  service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path: "/healthz"
          service.beta.kubernetes.io/azure-load-balancer-internal: "true"
          service.beta.kubernetes.io/azure-load-balancer-internal-subnet: alb-subnet
          service.beta.kubernetes.io/azure-pls-create: "true"
          service.beta.kubernetes.io/azure-pls-name: myServicePLS 
          service.beta.kubernetes.io/azure-pls-ip-configuration-subnet: "pls-subnet" # Private Link subnet name
          service.beta.kubernetes.io/azure-pls-ip-configuration-ip-address-count: "1"
          service.beta.kubernetes.io/azure-pls-proxy-protocol: "false"
          service.beta.kubernetes.io/azure-pls-visibility: "*"
          service.beta.kubernetes.io/azure-pls-auto-approval: "b2375b5f-8dab-4436-b87c-32bc7fdce5d0"
  podLabels:
    azure.workload.identity/use: "true"
  extraVolumes:
      - name: secrets-store-inline
        csi:
          driver: secrets-store.csi.k8s.io
          readOnly: true
          volumeAttributes:
            secretProviderClass: azure-kvname-user-msi
  extraVolumeMounts:
      - name: secrets-store-inline
        mountPath: "/mnt/secrets-store"
        readOnly: true
EOF
