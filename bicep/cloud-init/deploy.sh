LOCATION='australiaeast'
RG_NAME='cloud-init-test-rg'
CLOUD_INIT_CONTENT=$(cat ./cloudinit.txt)
EXTERNAL_IP=$(curl bot.whatismyipaddress.com)
SSH_PUBLIC_KEY=$(cat ~/.ssh/id_rsa.pub)

az group create --location $LOCATION --resource-group $RG_NAME

az deployment group create \
    --resource-group $RG_NAME \
    --name 'cloud-init-deployment' \
    --template-file ./azuredeploy.bicep \
    --parameters location=$LOCATION \
    --parameters adminPasswordOrKey="$SSH_PUBLIC_KEY" \
    --parameters customData="$CLOUD_INIT_CONTENT" \
    --parameters sourceAddressPrefix="$EXTERNAL_IP/32" \
    --parameters adminUsername='azureuser' \
    --parameters vnetAddressPrefix='10.0.0.0/16' \
    --parameters subnetAddressPrefix='10.0.0.0/24'
