LOCATION='westus2' # australiaeast region not currenlty supported for Azure Monitor
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
ADMIN_GROUP_OBJECT_ID="f6a900e2-df11-43e7-ba3e-22be99d3cede"
RG_NAME="aks-network-observability-$LOCATION-rg"
AKS_VERSION='1.27.3'

az group create --location $LOCATION --name $RG_NAME

az deployment group create \
    --resource-group $RG_NAME \
    --name aks-deployment \
    --template-file ./main.bicep \
    --parameters @main.parameters.json \
    --parameters location=$LOCATION \
    --parameters sshPublicKey="$SSH_KEY" \
    --parameters adminGroupObjectID=$ADMIN_GROUP_OBJECT_ID \
    --parameters aksVersion=$AKS_VERSION \
    --parameters dnsPrefix='aks-network-observability-rg'

CLUSTER_NAME=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.aksClusterName.value' -o tsv)

az aks get-credentials -g $RG_NAME -n $CLUSTER_NAME --admin --context 'aks-network-observability-rg' --admin --overwrite-existing
az aks update --resource-group $RG_NAME --name $CLUSTER_NAME --enable-network-observability

az resource create --resource-group $RG_NAME \
--namespace microsoft.monitor \
--resource-type accounts \
--name myAzureMonitor \
--location $LOCATION \
--properties '{}'

az grafana create --name myGrafana --resource-group $RG_NAME
grafanaId=$(az grafana show --name myGrafana --resource-group $RG_NAME --query id --output tsv)
azuremonitorId=$(az resource show --resource-group $RG_NAME --name myAzureMonitor --resource-type "Microsoft.Monitor/accounts" --query id --output tsv)

az aks update --name $CLUSTER_NAME \
    --resource-group $RG_NAME \
    --enable-azure-monitor-metrics \
    --azure-monitor-workspace-resource-id $azuremonitorId \
    --grafana-resource-id $grafanaId

kubectl get po -owide -n kube-system | grep ama-
# Use the ID 18814 to import the dashboard from Grafana's public dashboard repo.