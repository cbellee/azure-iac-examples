location='australiaeast'
deploymentName='myDeployment'
resourceGroupName='afd-agc-aks-rg'
sshPublicKey=$(cat ~/.ssh/id_rsa.pub)
identityResourceName='azure-alb-identity'
albNamespace='alb-helm'
albServiceAccountName='alb-controller-sa'

# create resource group
az group create \
  --name $resourceGroupName \
  --location $location

# create AKS cluster
az deployment group create \
  --name $deploymentName \
  --resource-group $resourceGroupName \
  --template-file ./deploy.bicep \
  --parameters location=$location \
  --parameters adminUserName='azureuser' \
  --parameters sshPublicKey="$sshPublicKey"

# get deployment outputs
clusterName=$(az deployment group show -g $resourceGroupName -n $deploymentName --query properties.outputs.aks_cluster_name.value -o tsv)
agcResourceId=$(az deployment group show -g $resourceGroupName -n $deploymentName --query properties.outputs.agc_id.value -o tsv)
agcFrontendName=$(az deployment group show -g $resourceGroupName -n $deploymentName --query properties.outputs.agc_frontend_name.value -o tsv)
agcSubnetId=$(az deployment group show -g $resourceGroupName -n $deploymentName --query properties.outputs.agc_subnet_id.value -o tsv)

# get AKS cluster credentials
az aks get-credentials -g $resourceGroupName -n $clusterName

# create identity federation
mcResourceGroup=$(az aks show --resource-group $resourceGroupName --name $clusterName --query "nodeResourceGroup" -o tsv)
mcResourceGroupId=$(az group show --name $mcResourceGroup --query id -otsv)
resourceGroupId=$(az group show --name $resourceGroupName --query id -otsv)

echo "Creating identity $identityResourceName in resource group $resourceGroupName..."
az identity create --resource-group $resourceGroupName --name $identityResourceName
principalId="$(az identity show -g $resourceGroupName -n $identityResourceName --query principalId -otsv)"

echo "Waiting 60 seconds to allow for replication of the identity..."
sleep 60

echo "Apply Reader role to the AKS managed cluster resource group for the newly provisioned identity"

az role assignment create \
    --assignee-object-id $principalId \
    --assignee-principal-type ServicePrincipal \
    --scope $mcResourceGroupId \
    --role "acdd72a7-3385-48ef-bd42-f606fba81ae7" # Reader role

# Delegate AppGw for Containers Configuration Manager role to RG containing Application Gateway for Containers resource
echo "Apply AppGw for Containers Configuration Manager role to the resource group containing the Application Gateway for Containers resource"
az role assignment create \
    --assignee-object-id $principalId \
    --assignee-principal-type ServicePrincipal \
    --scope $resourceGroupId \
    --role "fbc52c3f-28ad-4303-a892-8a056630b8f1" 

# Delegate Network Contributor permission for join to association subnet
echo "Apply Network Contributor role to the subnet containing the Application Gateway for Containers resource"
az role assignment create \
    --assignee-object-id $principalId \
    --assignee-principal-type ServicePrincipal \
    --scope $agcSubnetId \
    --role "4d97b98b-1d4f-4787-a291-c67834d212e7" 

echo "Get AKS OIDC issuer"
aksOidcIssuer="$(az aks show -n "$clusterName" -g "$resourceGroupName" --query "oidcIssuerProfile.issuerUrl" -o tsv)"

# create identity federation
az identity federated-credential create \
    --name "$albNamespace" \
    --identity-name "$identityResourceName" \
    --resource-group $resourceGroupName \
    --issuer "$aksOidcIssuer" \
    --subject "system:serviceaccount:$albNamespace:$albServiceAccountName"
    # --subject "system:serviceaccount:azure-alb-system:alb-controller-sa"

# install ALB controller
helm install alb-controller oci://mcr.microsoft.com/application-lb/charts/alb-controller \
    --create-namespace \
    --namespace $albNamespace \
    --version 0.6.3 \
    --set albController.namespace=$albNamespace \
    --set albController.podIdentity.clientID=$(az identity show -g $resourceGroupName -n $albNamespace --query clientId -o tsv)

# deploy services
kubectl apply -f https://trafficcontrollerdocs.blob.core.windows.net/examples/traffic-split-scenario/deployment.yaml

# deploy gateway API resources
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: Gateway
metadata:
  name: gateway-01
  namespace: test-infra
  annotations:
    alb.networking.azure.io/alb-id: $agcResourceId
spec:
  gatewayClassName: azure-alb-external
  listeners:
  - name: http-listener
    port: 80
    protocol: HTTP
    allowedRoutes:
      namespaces:
        from: Same
  addresses:
  - type: alb.networking.azure.io/alb-frontend
    value: $agcFrontendName
EOF

kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1beta1
kind: HTTPRoute
metadata:
  name: traffic-split-route
  namespace: test-infra
spec:
  parentRefs:
  - name: gateway-01
  rules:
  - backendRefs:
    - name: backend-v1
      port: 8080
      weight: 50
    - name: backend-v2
      port: 8080
      weight: 50
EOF

kubectl get httproute traffic-split-route -n test-infra -o yaml

fqdn=$(kubectl get gateway gateway-01 -n test-infra -o jsonpath='{.status.addresses[0].value}')
watch -n 1 curl http://$fqdn

# access via AFD
curl https://endpoint-1-d7gzc6fxbwb3fth9.b02.azurefd.net  -v
