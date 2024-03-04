LOCATION='australiaeast'
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
ADMIN_GROUP_OBJECT_ID="f6a900e2-df11-43e7-ba3e-22be99d3cede"
CLUSTER_NAME='aks-image-security'
RG_NAME="$CLUSTER_NAME-rg"
DNS_RG='external-dns-zones-rg'
DOMAIN='bellee.net'
RECORD_NAME='azure-vote-front'
KEY_PATH='/mnt/c/Users/cbellee/Documents/public_certs/bellee.net.key'
CERT_PATH='/mnt/c/Users/cbellee/Documents/public_certs/star_bellee_net.crt'
USER_PRINCIPAL_ID=$(az ad signed-in-user show --query id -o tsv)
CERT_NAME=bellee-io
CERT_SUBJECT="CN=bellee.io,O=MSFT,L=Sydney,ST=NSW,C=AU"
CERT_PATH=./${CERT_NAME}.pem
IDENTITY_NAME='ratify-umid'
RATIFY_NAMESPACE='gatekeeper-system'

sed "s/<CERT_SUBJECT>/$CERT_SUBJECT/g" ./kv-policy-template.json > ./kv-policy.json

az group create --location $LOCATION --name $RG_NAME

az deployment group create \
    --resource-group $RG_NAME \
    --name aks-deployment \
    --template-file ./main.bicep \
    --parameters @main.parameters.json \
    --parameters location=$LOCATION \
    --parameters sshPublicKey="$SSH_KEY" \
    --parameters adminGroupObjectID=$ADMIN_GROUP_OBJECT_ID \
    --parameters dnsPrefix=$CLUSTER_NAME \
    --parameters currentUserPrincipalId=$USER_PRINCIPAL_ID \
    --parameters enableWorkloadIdentity=true

CLUSTER_NAME=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.aksClusterName.value' -o tsv)
KV_NAME=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.keyVaultName.value' -o tsv)
ACR_NAME=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.acrName.value' -o tsv)
VAULT_URI=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.keyVaultUri.value' -o tsv)
VAULT_ID=$(az deployment group show --resource-group $RG_NAME --name aks-deployment --query 'properties.outputs.keyVaultId.value' -o tsv)

az aks get-credentials -g $RG_NAME -n $CLUSTER_NAME --admin --overwrite-existing --context $CLUSTER_NAME-admin

# create self-signed certificate for Notation 
az keyvault certificate create -n $CERT_NAME --vault-name $KV_NAME -p @kv-policy.json

# create identity for Ratify
az identity create --name "${IDENTITY_NAME}" --resource-group "${RG_NAME}" --location "${LOCATION}" --subscription "${SUBSCRIPTION_ID}"
IDENTITY_OBJECT_ID=$(az identity show --name "${IDENTITY_NAME}" --resource-group "${RG_NAME}" --query 'principalId' -o tsv)
IDENTITY_CLIENT_ID=$(az identity show --name ${IDENTITY_NAME} --resource-group ${RG_NAME} --query 'clientId' -o tsv)

# create role assignment for Ratify identity
az role assignment create \
  --assignee-object-id ${IDENTITY_OBJECT_ID} \
  --role acrpull \
  --scope subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RG_NAME}/providers/Microsoft.ContainerRegistry/registries/${ACR_NAME}

AKS_OIDC_ISSUER="$(az aks show -n ${CLUSTER_NAME} -g ${RG_NAME} --query "oidcIssuerProfile.issuerUrl" -o tsv)"

# establish trust between AKS and Ratify
az identity federated-credential create \
  --name ratify-federated-credential \
  --identity-name "${IDENTITY_NAME}" \
  --resource-group "${RG_NAME}" \
  --issuer "${AKS_OIDC_ISSUER}" \
  --subject system:serviceaccount:"${RATIFY_NAMESPACE}":"ratify-admin"

VAULT_URI=$(az keyvault show --name ${KV_NAME} --resource-group ${RG_NAME} --query "properties.vaultUri" -o tsv)

az keyvault set-policy --name ${KV_NAME} \
  --secret-permissions get \
  --object-id ${IDENTITY_OBJECT_ID}

az role assignment create \
  --assignee-object-id $IDENTITY_OBJECT_ID \
  --role "Key Vault Secrets Officer" \
  --scope $VAULT_ID

az aks show -g "${RG_NAME}" -n "${CLUSTER_NAME}" --query addonProfiles.azurepolicy

# install ratify
helm repo add ratify https://deislabs.github.io/ratify
helm repo update

helm install ratify \
    ./charts/ratify --atomic \
    --namespace gatekeeper-system --create-namespace \
    --set provider.enableMutation=false \
    --set featureFlags.RATIFY_CERT_ROTATION=true \
    --set akvCertConfig.enabled=true \
    --set akvCertConfig.vaultURI=${VAULT_URI} \
    --set akvCertConfig.cert1Name=${CERT_NAME} \
    --set akvCertConfig.tenantId=${TENANT_ID} \
    --set oras.authProviders.azureWorkloadIdentityEnabled=true \
    --set azureWorkloadIdentity.clientId=${IDENTITY_CLIENT_ID}

# custom policy assignment
# custom_policy=$(curl -L https://deislabs.github.io/ratify/library/default/customazurepolicy.yaml)
custom_poliyc=$(curl -L https://github.com/deislabs/ratify/blob/main/library/default/customazurepolicy.json)
definition_name="ratify-default-custom-policy"
scope=$(az aks show -g "${RG_NAME}" -n "${CLUSTER_NAME}" --query id -o tsv)

definition_id=$(az policy definition create \
  --name "${definition_name}" \
  --rules "$(echo "${custom_policy}" | jq .policyRule)" \
  --params "$(echo "${custom_policy}" | jq .parameters)" \
  --mode "Microsoft.Kubernetes.Data" \
  --query id -o tsv)

assignment_id=$(az policy assignment create \
  --policy "${definition_id}" \
  --name "${definition_name}" \
  --scope "${scope}" \
  --query id \
  -o tsv)

echo "Please wait policy assignmet with id ${assignment_id} taking effect"
echo "It often requires 15 min"
echo "You can run 'kubectl get constraintTemplate ratifyverification' to verify the policy takes effect"

# install K8S objects
: '
helm repo add azure-samples https://azure-samples.github.io/helm-charts/
helm repo add nginx-ingress https://kubernetes.github.io/ingress-nginx

helm install azure-vote azure-samples/azure-vote --set serviceType=ClusterIP

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --create-namespace \
  --namespace nginx-ingress \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz

kubectl create secret tls azure-vote-cert-secret --key $KEY_PATH --cert $CERT_PATH -n default

kubectl apply -f - << EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: azure-vote-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/backend-protocol: "HTTP"
    nginx.ingress.kubernetes.io/ssl-redirect: "false"
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  tls:
  - hosts:
    - "azure-vote-front.kainiindustries.net"
    secretName: azure-vote-cert-secret
  ingressClassName: nginx
  rules:
  - host: azure-vote-front.kainiindustries.net
    http:
      paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: azure-vote-front
              port:
                number: 80
EOF

INGRESS_VIP=`kubectl get ingress azure-vote-ingress  -o jsonpath='{.status.loadBalancer.ingress[0].ip}'`

az network dns record-set a delete -g $DNS_RG -z $DOMAIN -n $RECORD_NAME
az network dns record-set a add-record -g $DNS_RG -z $DOMAIN -n $RECORD_NAME -a $INGRESS_VIP --ttl 300
'