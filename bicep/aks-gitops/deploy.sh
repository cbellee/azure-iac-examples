ENVIRONMENTS=(staging production)
LOCATION='australiaeast'
GIT_REPO_URL='https://github.com/cbellee/gitops-flux2-kustomize-helm-mt'
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
ADMIN_GROUP_OBJECT_ID="f6a900e2-df11-43e7-ba3e-22be99d3cede"

for e in "${ENVIRONMENTS[@]}"
do
    echo "deploying environment: $e"
    RG_NAME="aks-gitops-$e-rg"

    az group create --location $LOCATION --name $RG_NAME

    az deployment group create \
        --resource-group $RG_NAME \
        --name aks-deployment \
        --template-file ./main.bicep \
        --parameters @main.parameters.json \
        --parameters environment=$e \
        --parameters gitRepoUrl=$GIT_REPO_URL \
        --parameters sshPublicKey="$SSH_KEY" \
        --parameters adminGroupObjectID=$ADMIN_GROUP_OBJECT_ID

    CLUSTER_NAME=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.aksClusterName.value' -o tsv)

    az aks get-credentials -g $RG_NAME -n $CLUSTER_NAME --admin --overwrite-existing --context "aks-gitops-$e"
done

