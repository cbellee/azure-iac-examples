SUBSCRIPTION_ID=$(az account show --query id -o tsv)
az ad sp create-for-rbac -n crossplane-provider-sp --sdk-auth --role Owner --scopes "/subscriptions/$SUBSCRIPTION_ID" > ./azure-credentials.json
AZURE_CLIENT_ID=`cat ./azure-credentials.json | jq .'clientId' -r`

# add required Azure Active Directory permissions
RW_ALL_APPS='1cda74f2-2616-4834-b122-5cb1b07f8a59'
RW_DIR_DATA='78c8a3c8-a07e-4b9e-af1b-b5ccab50a175'
AAD_GRAPH_API='00000002-0000-0000-c000-000000000000'

# add app permissions
az ad app permission add --id $AZURE_CLIENT_ID --api $AAD_GRAPH_API --api-permissions $RW_ALL_APPS=Role $RW_DIR_DATA=Role

# grant (activate) the permissions
az ad app permission grant --id $AZURE_CLIENT_ID --api $AAD_GRAPH_API --scope "/subscriptions/$SUBSCRIPTION_ID"

# grant admin consent to the service princinpal you created
az ad app permission admin-consent --id $AZURE_CLIENT_ID

helm repo add crossplane-stable https://charts.crossplane.io/stable && helm repo update

helm install crossplane \
    crossplane-stable/crossplane \
    --namespace crossplane-system \
    --create-namespace 

cat <<EOF | kubectl apply -f -
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-azure
spec:
  package: xpkg.upbound.io/upbound/provider-azure:v0.36.0
EOF

kubectl create secret \
generic azure-secret \
-n crossplane-system \
--from-file=creds=./azure-credentials.json

cat <<EOF | kubectl apply -f -
apiVersion: azure.upbound.io/v1
metadata:
  name: default
kind: ProviderConfig
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: azure-secret
      key: creds
EOF
