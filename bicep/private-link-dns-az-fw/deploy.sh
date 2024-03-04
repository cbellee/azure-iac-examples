bicep build ./main.bicep

# vars
RG_NAME=pl-dns-poc-rg
LOCATION=australiaeast
PREFIX=poc
VPN_SHARED_SECRET=Passw0rd123
# get router external IP
EXT_IP=$(dig +short 5dd905890988.sn.mynetname.net)

az group create --name $RG_NAME --location $LOCATION

az deployment group create --template-file ./main.json \
--resource-group $RG_NAME \
--parameters vpnSharedSecret=$VPN_SHARED_SECRET \
--parameters localGatewayIpAddress=$EXT_IP \
--parameters prefix=$PREFIX
