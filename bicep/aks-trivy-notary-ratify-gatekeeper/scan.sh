!#/bin/bash

ACR_NAME='acru33faoz5hdulu'
SRC_PATH='/mnt/c/Users/cbellee/repos/github.com/aks-voting-app/src'
FRONT_IMAGE='azure-vote-front'
FRONT_IMAGE_TAG=v1.0.0
BACK_IMAGE='azure-vote-back'
BACK_IMAGE_TAG=v1.0.0
CERT_NAME=bellee-io
CERT_PATH=./${CERT_NAME}.pem
KV_NAME='kv-u33faoz5hdulu'
STORE_TYPE="ca"
STORE_NAME="bellee.io"
CERT_SUBJECT="CN=bellee.io,O=MSFT,L=Sydney,ST=NSW,C=AU"

# install trivy
sudo apt-get install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

# Download, extract and install Notation
curl -Lo notation.tar.gz https://github.com/notaryproject/notation/releases/download/v1.0.0/notation_1.0.0_linux_amd64.tar.gz
tar xvzf notation.tar.gz
sudo cp ./notation /usr/local/bin

# DOwnload the KV plugin
mkdir -p ~/.config/notation/plugins/azure-kv
curl -Lo notation-azure-kv.tar.gz https://github.com/Azure/notation-azure-kv/releases/download/v1.0.1/notation-azure-kv_1.0.1_linux_amd64.tar.gz 
tar xvzf notation-azure-kv.tar.gz -C ~/.config/notation/plugins/azure-kv

# build images from src
docker build -t $FRONT_IMAGE:$FRONT_IMAGE_TAG $SRC_PATH/app/2.0 
docker build -t $BACK_IMAGE:$BACK_IMAGE_TAG $SRC_PATH/storage/2.0

# scan image using Trivy
trivy image $FRONT_IMAGE:$FRONT_IMAGE_TAG
trivy image $FRONT_IMAGE:$FRONT_IMAGE_TAG | grep Total

# output vulns JSON file
trivy image $FRONT_IMAGE:$FRONT_IMAGE_TAG --format json --output ./$FRONT_IMAGE:$FRONT_IMAGE_TAG-patch.json

# scan image using Trivy
trivy image $BACK_IMAGE:$BACK_IMAGE_TAG
trivy image $BACK_IMAGE:$BACK_IMAGE_TAG | grep Total

# output vulns JSON file
trivy image $BACK_IMAGE:$BACK_IMAGE_TAG --format json --output ./$BACK_IMAGE:$BACK_IMAGE_TAG-patch.json

# tag & push images to ACR
az acr login --name $ACR_NAME
docker tag $FRONT_IMAGE:$FRONT_IMAGE_TAG $ACR_NAME.azurecr.io/$FRONT_IMAGE:$FRONT_IMAGE_TAG
docker tag $BACK_IMAGE:$BACK_IMAGE_TAG $ACR_NAME.azurecr.io/$BACK_IMAGE:$BACK_IMAGE_TAG
docker push $ACR_NAME.azurecr.io/$FRONT_IMAGE:$FRONT_IMAGE_TAG && docker push $ACR_NAME.azurecr.io/$FRONT_IMAGE:$FRONT_IMAGE_TAG
docker push $ACR_NAME.azurecr.io/$BACK_IMAGE:$BACK_IMAGE_TAG && docker push $ACR_NAME.azurecr.io/$BACK_IMAGE:$BACK_IMAGE_TAG

# patch images using Copacetic
# inatall tool
wget https://github.com/project-copacetic/copacetic/releases/download/v0.4.1/copa_0.4.1_linux_amd64.tar.gz
tar -xzf copa_0.4.1_linux_amd64.tar.gz
sudo mv copa /usr/local/bin

# start buildkit & run copa patch command
docker buildx create --name copademo
docker buildx ls

copa patch -i $ACR_NAME.azurecr.io/$FRONT_IMAGE:$FRONT_IMAGE_TAG -r ./$FRONT_IMAGE:$FRONT_IMAGE_TAG-patch.json -t v1.0.0-patched -a buildx://copademo
copa patch -i $ACR_NAME.azurecr.io/$BACK_IMAGE:$BACK_IMAGE_TAG -r ./$BACK_IMAGE:$BACK_IMAGE_TAG-patch.json -t v1.0.0-patched -a buildx://copademo

# list patched images
docker images | grep v1.0.0-patched

# display vulns in patched image - should now be 'Total: 0'
trivy image --vuln-type os --ignore-unfixed $ACR_NAME.azurecr.io/$FRONT_IMAGE:$FRONT_IMAGE_TAG-patched | grep Total
trivy image --vuln-type os --ignore-unfixed $ACR_NAME.azurecr.io/$BACK_IMAGE:$BACK_IMAGE_TAG-patched | grep Total

# push patched images to ACR
docker push $ACR_NAME.azurecr.io/$FRONT_IMAGE:$FRONT_IMAGE_TAG-patched
docker push $ACR_NAME.azurecr.io/$BACK_IMAGE:$BACK_IMAGE_TAG-patched

# sign patched images using Notary
FRONT_IMAGE_DIGEST=$(az acr manifest show $ACR_NAME.azurecr.io/$FRONT_IMAGE:$FRONT_IMAGE_TAG-patched --query 'config.digest' -o tsv)
BACK_IMAGE_DIGEST=$(az acr manifest show $ACR_NAME.azurecr.io/$BACK_IMAGE:$BACK_IMAGE_TAG-patched --query 'config.digest' -o tsv)

FRONT_IMAGE_DIGEST=$(az acr manifest show-metadata --name $FRONT_IMAGE:$FRONT_IMAGE_TAG-patched --registry $ACR_NAME --query digest -o tsv)
BACK_IMAGE_DIGEST=$(az acr manifest show-metadata --name $BACK_IMAGE:$BACK_IMAGE_TAG-patched --registry $ACR_NAME --query digest -o tsv)

KEY_ID=$(az keyvault certificate show -n $CERT_NAME --vault-name $KV_NAME --query 'kid' -o tsv)
notation sign --signature-format cose --id $KEY_ID --plugin azure-kv --plugin-config self_signed=true $ACR_NAME.azurecr.io/$FRONT_IMAGE:$FRONT_IMAGE_TAG@$FRONT_IMAGE_DIGEST
notation sign --signature-format cose --id $KEY_ID --plugin azure-kv --plugin-config self_signed=true $ACR_NAME.azurecr.io/$BACK_IMAGE:$BACK_IMAGE_TAG@$BACK_IMAGE_DIGEST

notation ls $ACR_NAME.azurecr.io/$FRONT_IMAGE:$FRONT_IMAGE_TAG@$FRONT_IMAGE_DIGEST
notation ls $ACR_NAME.azurecr.io/$BACK_IMAGE:$BACK_IMAGE_TAG@$BACK_IMAGE_DIGEST

# verify
az keyvault certificate download --name $CERT_NAME --vault-name $KV_NAME --file $CERT_PATH
notation cert add --type $STORE_TYPE --store $STORE_NAME $CERT_PATH
notation cert ls

sed "s/<REGISTRY>/$ACR_NAME.azurecr.io/g;s/<REPO>/$FRONT_IMAGE/g;s/<STORE_TYPE>/$STORE_TYPE/g;s/<STORE_NAME>/$STORE_NAME/g;s/<CERT_SUBJECT>/$CERT_SUBJECT/g" ./trust-policy-template.json > ./trust-policy.json

az acr login --name $ACR_NAME
notation policy import ./trust-policy.json
notation policy show
notation verify $ACR_NAME.azurecr.io/$FRONT_IMAGE:$FRONT_IMAGE_TAG@$FRONT_IMAGE_DIGEST