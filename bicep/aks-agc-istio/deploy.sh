adminGroupObjectId='f6a900e2-df11-43e7-ba3e-22be99d3cede'
rgName='aks-agc-istio-rg'
location='australiaeast'
sshPublicKey="$(cat ~/.ssh/id_rsa.pub)"
kubernetesVersion='1.28.3'
agcNamespace='agc-infra'

az group create -n $rgName -l $location

az deployment group create \
  --name 'infra-deployment' \
  --resource-group $rgName \
  --template-file ./main.bicep \
  --parameters location=$location \
  --parameters adminGroupObjectId=$adminGroupObjectId \
  --parameters sshPublicKey="$sshPublicKey" \
  --parameters kubernetesVersion=$kubernetesVersion \
  --parameters istioVersion='asm-1-20'

output=$(az deployment group show \
  --name 'infra-deployment' \
  --resource-group $rgName)

rgId=$(echo $output | jq .properties.outputs.rgId.value -r)
umidId=$(echo $output | jq .properties.outputs.umidId.value -r)
umidName=$(echo $output | jq .properties.outputs.umidName.value -r)
agcSubnetId=$(echo $output | jq .properties.outputs.agcSubnetId.value -r)
agcId=$(echo $output | jq .properties.outputs.agcId.value -r)
agcFrontend=$(echo $output | jq .properties.outputs.agcFrontend.value -r)
agcUmidPrincipalId=$(echo $output | jq .properties.outputs.agcUmidPrincipalId.value -r)
nodeResourceGroup=$(echo $output | jq .properties.outputs.nodeResourceGroup.value -r)
clusterName=$(echo $output | jq .properties.outputs.clusterName.value -r)
agcName=$(echo $output | jq .properties.outputs.agcName.value -r)
oidcIssuer=$(az aks show -n $clusterName -g $rgName --query "oidcIssuerProfile.issuerUrl" -o tsv)
mcResourceGroupId=$(az group show --name $nodeResourceGroup --query id -o tsv)

az role assignment create \
    --assignee-object-id $agcUmidPrincipalId \
    --assignee-principal-type ServicePrincipal \
    --scope $rgId \
    --role "fbc52c3f-28ad-4303-a892-8a056630b8f1"

az identity federated-credential create \
    --name "azure-alb-identity" \
    --identity-name $umidName \
    --resource-group $rgName \
    --issuer $oidcIssuer \
    --subject "system:serviceaccount:$agcNamespace:alb-controller-sa"

az aks get-credentials -n $clusterName -g $rgName --admin

kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: $agcNamespace
EOF

kubectl apply -f - <<EOF
apiVersion: alb.networking.azure.io/v1
kind: ApplicationLoadBalancer
metadata:
  name: agc
  namespace: $agcNamespace
spec:
  associations:
  - $agcSubnetId
EOF

kubectl get applicationloadbalancer -n $agcNamespace

helm install alb-controller oci://mcr.microsoft.com/application-lb/charts/alb-controller \
    --namespace $agcNamespace \
    --version '1.0.0' \
    --set albController.namespace=$agcNamespace \
    --set albController.podIdentity.clientID=$(az identity show -g $rgName -n azure-alb-identity --query clientId -o tsv)

kubectl get pods -n $agcNamespace
kubectl get gatewayclass azure-alb-external -o yaml

# install bookinfo app
# kubectl label namespace default istio-injection=enabled
kubectl label namespace default istio.io/rev=asm-1-20
kubectl apply -f ./bookinfo/platform/kube/bookinfo.yaml

kubectl exec "$(kubectl get pod -l app=ratings -o jsonpath='{.items[0].metadata.name}')" -c ratings -- curl -sS productpage:9080/productpage | grep -o "<title>.*</title>"

# create TLS secret
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: listener-tls-secret
  namespace: default
data:
  tls.crt: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tDQpNSUlHTGpDQ0JSYWdBd0lCQWdJUUIzUlhGUEUxckpaeit4VTJtZUFkeVRBTkJna3Foa2lHOXcwQkFRc0ZBREJnDQpNUXN3Q1FZRFZRUUdFd0pWVXpFVk1CTUdBMVVFQ2hNTVJHbG5hVU5sY25RZ1NXNWpNUmt3RndZRFZRUUxFeEIzDQpkM2N1WkdsbmFXTmxjblF1WTI5dE1SOHdIUVlEVlFRREV4WkhaVzlVY25WemRDQlVURk1nVWxOQklFTkJJRWN4DQpNQjRYRFRJek1EZ3dOekF3TURBd01Gb1hEVEkwTURrd05qSXpOVGsxT1Zvd0Z6RVZNQk1HQTFVRUF3d01LaTVpDQpaV3hzWldVdWJtVjBNSUlCSWpBTkJna3Foa2lHOXcwQkFRRUZBQU9DQVE4QU1JSUJDZ0tDQVFFQXU1SWIvUlc4DQpEcU9VYjA5NGw0ZG5kNWRibXZMcHVZYnZ4Tk5nUkRzcDZvVHZGdUU3QjQvN2d4aDJ4eVdVQ3dGcUUrNE9VVWlODQpjZlgrVkFVdm8zSjFneTBFa3dONHRhMFlpMzlhcmx2QkVpL3BRK3dseXpaTDZtY3d3Y1pKMFpPQ2cwcFFzOTc2DQpKT0dxUGdTbHlobmdMUExlSVpqV0pMcWtVU29CRzFKRjllY0NPM1FCVEViNldvQTVnZDZvbEhzVHpmOExGKy9tDQp4eHV6a1lJSy9oRXN5Zk9VODAvWUU4OUp6aUkwUnMrM2JvRklpNEdkMm9LR01HMTdFZEhoSWpRVk1naW1Td3Y2DQpQQ1EwajYvMGZ6K0h2SEFkZFFWSldJcC9vVTJRWVVLaFd0bU9NTTArNWNIYWRDZnkrSkVDUlhmajgwMSt6MmRqDQpBWGNESDkwWjB2TTNlUUlEQVFBQm80SURLekNDQXljd0h3WURWUjBqQkJnd0ZvQVVsRS9VWFl2a3BPS21nUDc5DQoyUGtBNzZPK0FsY3dIUVlEVlIwT0JCWUVGTzcyM1gzUXNuQ1BLN0xkalYzQktCUFQvbmpMTUM0R0ExVWRFUVFuDQpNQ1dDRENvdVltVnNiR1ZsTG01bGRJSVZLaTVwYm5SbGNtNWhiQzVpWld4c1pXVXVibVYwTUE0R0ExVWREd0VCDQovd1FFQXdJRm9EQWRCZ05WSFNVRUZqQVVCZ2dyQmdFRkJRY0RBUVlJS3dZQkJRVUhBd0l3UHdZRFZSMGZCRGd3DQpOakEwb0RLZ01JWXVhSFIwY0RvdkwyTmtjQzVuWlc5MGNuVnpkQzVqYjIwdlIyVnZWSEoxYzNSVVRGTlNVMEZEDQpRVWN4TG1OeWJEQStCZ05WSFNBRU56QTFNRE1HQm1lQkRBRUNBVEFwTUNjR0NDc0dBUVVGQndJQkZodG9kSFJ3DQpPaTh2ZDNkM0xtUnBaMmxqWlhKMExtTnZiUzlEVUZNd2RnWUlLd1lCQlFVSEFRRUVhakJvTUNZR0NDc0dBUVVGDQpCekFCaGhwb2RIUndPaTh2YzNSaGRIVnpMbWRsYjNSeWRYTjBMbU52YlRBK0JnZ3JCZ0VGQlFjd0FvWXlhSFIwDQpjRG92TDJOaFkyVnlkSE11WjJWdmRISjFjM1F1WTI5dEwwZGxiMVJ5ZFhOMFZFeFRVbE5CUTBGSE1TNWpjblF3DQpDUVlEVlIwVEJBSXdBRENDQVlBR0Npc0dBUVFCMW5rQ0JBSUVnZ0Z3QklJQmJBRnFBSGNBN3MzUVpOWGJHczdGDQpYTGVkdE0wVG9qS0hSbnk4N043RFVVaFpSbkVmdFpzQUFBR0p6aEpSNGdBQUJBTUFTREJHQWlFQTRPNUxjdTRUDQpiSUtMTjBPK3F0ZS9MSnlNRkJWWS9IQjJ6Q3c0cHpmbTFjMENJUUNhR2tPQXNUakdUQlhqQVJlV01rTmh3N3dXDQpCaVFqeVphQkRrZmNtQ1dEcXdCMkFFaXc0MnZhcGtjMEQrVnFBdnFkTU9zY1VnSExWdDBzZ2RtN3Y2czUySVJ6DQpBQUFCaWM0U1Vjb0FBQVFEQUVjd1JRSWhBTjlmZ0xVc1FzRm9YWXVOV2hEYnZHM3lhdGdRWUwwSEdURGZiUlRCDQpmOER0QWlBY3lONDNuVVNocTc3NVQ4cjhycmhNVE5TL2Uwdk4zaC9LalpJVUpLZFQ3UUIzQU5xMnYycy90YllpDQpuNXZDdTF4cjZIQ1JjV3k3VVlTRk5MMmtQVEJJMS91ckFBQUJpYzRTVVg0QUFBUURBRWd3UmdJaEFPdkhDWktEDQpsWjZJTWJidWVJS3o1WkYwTGNrRTB2NEM0bjk1cUpaTnhQaVRBaUVBeThuMDkwbnFTdzlwaEJVY2oxOE0rUUlBDQpad1d2ejFMS0hSbHdsSkNaQmc0d0RRWUpLb1pJaHZjTkFRRUxCUUFEZ2dFQkFCWi8wcDVicHNBc0phY3crMFhUDQozWUFYaEd0TEsrVHNZakxKUGZJSlE2RHgvckxxekhjcXkzZzRDajBZelJnVkwrWEUrZElyancvbjFqQmJqSkNODQo2VjZSQ2NVeiswdGhqc0VVTExDS3hZd1RJdVRabCtPV1lXTFJ2Zmx2UzlLcHFWZnV6TE1xVnc4c1l1aVRUa1hEDQpoM0VJV21CWTdFdXlXSm1rYkpsaUtGQ3Q5NGZoWXM1MkQ0MEhBSlBtb3dGeEo2cjQ0NFlMS1huSStEM0JVY2FPDQpBd2dBUUxIMkRRaEZoYW03YkRjRW84OVNZZDM4SDh3WVpJRG92NGlvY21ENEgySkp5MGNBSXdwSjZvSXdybW9FDQppamJtS2lEYmpwMU5kREFEd2tNY1RVa3E4Y2RiVWlSR3ovQVNnMHRaUXlZQkRUOTlCUmkwTEUrWXo0cnEzdHdYDQptVEU9DQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tDQo=
  tls.key: LS0tLS1CRUdJTiBSU0EgUFJJVkFURSBLRVktLS0tLQpNSUlFb3dJQkFBS0NBUUVBdTVJYi9SVzhEcU9VYjA5NGw0ZG5kNWRibXZMcHVZYnZ4Tk5nUkRzcDZvVHZGdUU3CkI0LzdneGgyeHlXVUN3RnFFKzRPVVVpTmNmWCtWQVV2bzNKMWd5MEVrd040dGEwWWkzOWFybHZCRWkvcFErd2wKeXpaTDZtY3d3Y1pKMFpPQ2cwcFFzOTc2Sk9HcVBnU2x5aG5nTFBMZUlaaldKTHFrVVNvQkcxSkY5ZWNDTzNRQgpURWI2V29BNWdkNm9sSHNUemY4TEYrL214eHV6a1lJSy9oRXN5Zk9VODAvWUU4OUp6aUkwUnMrM2JvRklpNEdkCjJvS0dNRzE3RWRIaElqUVZNZ2ltU3d2NlBDUTBqNi8wZnorSHZIQWRkUVZKV0lwL29VMlFZVUtoV3RtT01NMCsKNWNIYWRDZnkrSkVDUlhmajgwMSt6MmRqQVhjREg5MFowdk0zZVFJREFRQUJBb0lCQURCMTIwMVQ1RFpVQlBHTgpNcmJUZ09QZzh3WGhaSWxPVjN3ZXNHeHdiSy91a0diMDRlOWVQN2pyQlNVR2pHMGJmSENSdkprN2lXKzhBbTFxCnVaZ2M1a2R4eGhERmdOWlBWbHdVRnpXYzl4RGYyQUI0Ym50R0YrOERvaEV1VGJ3YnhFaHZWdEpoOVhhNTV1WUgKQlY1bHVRbGo1Z2dBR0xOOGxSOXpIcjRVVDRic0t1ZjVIaEwzTVh3dXpFZzhlUDhWRzQ3T1pUTncvUzBxUTlmaApsazlHSUloM3VMOXM1a2lKWTRpbW01Sm4yZzNTT3RQbmVITVRjb05HZitYb0hXMEtQcmtDd2F4a2lRdSszVVRuCjJpZGkwL0RUSThVbDNVRUxSZ21obWc3QWhUdGhLVlB4RzlWLzlWSWl1L1o1eXgxU0FUMWMxaDZ4ODhHa1BMdGIKU3I4Mk5nRUNnWUVBM0o2S0NkWDNncEh2bm0vUkFXN3lIVHhmT2VjWGhkUW85N002SUZScC92cmFBT01vazZHVQpvRVV6Y0RBd1FUZklVNEZvTnNxbk9pMmltY2VPZitLZ0dESlphblhWYVR3YVdHcnpPMXViemFtcUNUUlEvUXBpCnc4MUlkVFkyeWxOWGNXTDJhbDY4MVBDbWdZNkpMcnEzTm4zSWJheURhc09RTUg2a3l4dXNSTEVDZ1lFQTJhYkYKZDhza0NkaG4xa3JVZTdzUU5mTkQ4OEdJdUl4RUxuQ3Nzdk0vU0RMRE10UWlsYlN5MUZKcERDbHdwVDFlNVpYagpSU2Y5RkdRbFB0ZVpKWW8yUUpBa1plQ2NKWGVwN1lFQ0trMjNnMWpDZ0lDcUdnRTRZUHBPdGlwMmhhRG5HVWVhCmVqSU5ZcDN1NzMyb3Uyek1ySUJBMjBJWWZNRGxOdWc0UnBMNThVa0NnWUVBc0R6UnBwUFBlZldjaG1OcWdndWYKeTYwTG9SU3pITXhqd2FQaC9pdVExUWlOR0FKZXlyaGNJei9FbkkxU0x2Y2h4MXRyNWNFem4yMFBKR3Rlc1ZoWApiWnpqQXdHSWJ0MTlhajVkZVlCdjBQWUZCLzlMNXlmaHgrcDRSSEgvaU5iVTFwWW9wTVp6Y0dPaGo0Tk9vUTYxCkJ3bXFEN3FzN0orMjBwYUlqRnZaM0xFQ2dZQmVnQm1HN00ybDlLOEpEUTU2OW5xUVlpSWo2T2phOEJQK2NlK1oKOXlHSDBIcU9UQ3NFQXlRT0tnWHdRT0htN09HU0gyVkJOcDZjeHVxaEFXMCtMbWRsMnUvaXlBWWtBblBtYWpndApjL2IwOFlucHozT0x2UEhrc1dtUmtKaExadFJRVnBXTTdzUi9DQUdoUEZjUm9haXdVVE5Ydjdmd0dyU3JCV0xCCnliajUrUUtCZ0VmS3V5aCtIQ0pHUlJjVC9TSDljOWo1L2k4ekJRYUczblRPSTBLU0Q5MzdyUDhLcUhSa3pZU0kKcHE0bktHRUg1QnoyZ1dyUlc3enlGbUZhRU1NL3M2SnpEcmh2L2dKWThoVllBeDRxSlV0OStPeG5CN3kvSDduVwppUUx1R1c2cHdMVEk0TFRvWmY1Vnd1WnovRDdFME9JeGtQRE5KaHJna3hDVjhyWTNxUWpxCi0tLS0tRU5EIFJTQSBQUklWQVRFIEtFWS0tLS0tCg==
type: kubernetes.io/tls
EOF

# create Gateway
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: gateway-01
  namespace: default
  annotations:
    alb.networking.azure.io/alb-id: $agcId
spec:
  gatewayClassName: azure-alb-external
  listeners:
  - name: https-listener
    port: 443
    protocol: HTTPS
    allowedRoutes:
      namespaces:
        from: Same
    tls:
      mode: Terminate
      certificateRefs:
      - kind : Secret
        group: ""
        name: listener-tls-secret
  addresses:
  - type: alb.networking.azure.io/alb-frontend
    value: $agcFrontend
EOF

kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: https-route
  namespace: default
spec:
  parentRefs:
  - name: gateway-01
  rules:
  - backendRefs:
    - name: productpage
      port: 9080
EOF

kubectl get httproute https-route -n default -o yaml

fqdn=$(kubectl get gateway gateway-01 -n default -o jsonpath='{.status.addresses[0].value}')

curl https://$fqdn/productpage  -kv