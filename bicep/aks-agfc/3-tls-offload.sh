#########################
# SSL offload
#########################

# create namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: tls-offload
EOF

# create echo app
kubectl apply -f ./tls-offload/echo-app.yaml

# create gateway
kubectl apply -f ./tls-offload/gateway.yaml

# create http-route
kubectl apply -f ./tls-offload/http-route.yaml

# verify http-route
kubectl get httproute https-route -n tls-offload -o yaml

fqdn=$(kubectl get gateway gateway-02 -n tls-offload -o jsonpath='{.status.addresses[0].value}')
curl --insecure https://$fqdn/ -v
