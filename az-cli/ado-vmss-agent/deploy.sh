LOCATION='australiaeast'
POOL_NAME='ado-vmss-agent-pool'
RG_NAME='ado-vmss-agent-pool-rg'
VNET_NAME='ado-vmss-agent-pool-vnet'
SUBSCRIPTION_ID=`az account show --query id --output tsv`

az group create --name $RG_NAME --location $LOCATION

UMID_1_ID=`az identity create --name 'ado-umid-1' --resource-group $RG_NAME --query id --output tsv`
UMID_1_PID=$(az identity show -n 'ado-umid-1' -g ado-vmss-agent-pool-rg --query principalId --out tsv)
az role assignment create --assignee $UMID_1_PID --role 'Owner' --scope /subscriptions/$SUBSCRIPTION_ID

UMID_2_ID=`az identity create --name 'ado-umid-2' --resource-group $RG_NAME --query id --output tsv`
UMID_2_PID=$(az identity show -n 'ado-umid-2' -g ado-vmss-agent-pool-rg --query principalId --out tsv)
az role assignment create --assignee $UMID_2_PID --role 'Owner' --scope /subscriptions/$SUBSCRIPTION_ID

az network vnet create \
--name $VNET_NAME \
--resource-group $RG_NAME \
--address-prefix 10.0.0.0/16 \
--subnet-name vmss-subnet --subnet-prefixes 10.0.0.0/24

az network vnet subnet create \
--resource-group $RG_NAME \
--name asp-subnet \
--vnet-name $VNET_NAME \
--address-prefixes 10.0.1.0/24

az vmss create \
--name $POOL_NAME \
--resource-group $RG_NAME \
--image UbuntuLTS \
--vm-sku Standard_D2_v3 \
--storage-sku StandardSSD_LRS \
--admin-username localadmin \
--authentication-type SSH \
--instance-count 1 \
--disable-overprovision \
--upgrade-policy-mode manual \
--single-placement-group false \
--platform-fault-domain-count 1 \
--load-balancer "" \
--assign-identity  [system] $UMID_1_ID $UMID_2_ID \
--custom-data cloud-init.txt
