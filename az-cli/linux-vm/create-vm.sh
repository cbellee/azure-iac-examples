# variables
SUBSCRIPTION_ID="f216c0c2-6d77-45a4-affb-e865e0f6535e"
LOCATION="australiaeast"
PREFIX="ki"
RG_NAME="$PREFIX-vnet-rg"
VM_NAME="$PREFIX-vm-1"
VNET_NAME="$PREFIX-vnet"
SUBNET_NAME="$PREFIX-vm-subnet"
VIP_NAME="$VM_NAME-vip"
NSG_NAME="$PREFIX-ssh-nsg"
NIC_NAME="$VM_NAME-nic"
VM_SKU="Standard_F2s_v2"
DENIED_VM_SKU="Standard_NC12"
USER_NAME="azureuser"
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)

# set account context
az account set -s $SUBSCRIPTION_ID

# create resource group
az group create --name $RG_NAME --location $LOCATION

# create vnet
az network vnet create -g $RG_NAME \
	-n $VNET_NAME \
	--address-prefix 10.0.0.0/16 \
	--subnet-name $SUBNET_NAME \
	--subnet-prefix 10.0.0.0/24

# create vip
az network public-ip create \
	--resource-group $RG_NAME \
	--name $VIP_NAME \
	--dns-name $VM_NAME \
	--allocation-method Static

# create nsg + ssh rule
az network nsg create \
    --resource-group $RG_NAME \
    --name $NSG_NAME

az network nsg rule create \
    --resource-group $RG_NAME \
    --nsg-name $NSG_NAME \
    --name "allow-internet-inbound-ssh" \
    --protocol tcp \
    --priority 1000 \
    --destination-port-range 22 \
    --access allow

# create vm nic
az network nic create \
    --resource-group $RG_NAME \
    --name $NIC_NAME \
    --vnet-name $VNET_NAME \
    --subnet $SUBNET_NAME \
    --public-ip-address $VIP_NAME \
    --network-security-group $NSG_NAME

# create vm
az vm create \
    --resource-group $RG_NAME \
	--location $LOCATION \
	--name $VM_NAME \
	--image UbuntuLTS \
	--admin-username $USER_NAME \
	--nics $NIC_NAME \
	--ssh-key-values ~/.ssh/id_rsa.pub \
	--size $DENIED_VM_SKU 

# get vm public IP & ssh to it
VM_DNS=$(az vm show -d --resource-group $RG_NAME --name $VM_NAME --query "fqdns" -o tsv)

echo "SSH: $USER_NAME@$VM_DNS"
ssh "$USER_NAME@$VM_DNS"
