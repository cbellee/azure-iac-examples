
#########################
###################
# traffic-split
###################

# create namespace
kubectl apply -f - <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: traffic-split
EOF

# create gateway
kubectl apply -f ./traffic-split/gateway.yaml

# create apps
kubectl apply -f ./traffic-split/deployment.yaml # https://trafficcontrollerdocs.blob.core.windows.net/examples/traffic-split-scenario/deployment.yaml

# create http-route 
kubectl apply -f ./traffic-split/http-route.yaml

# verify http-route
kubectl get httproute traffic-split-route -n traffic-split -o yaml

# get the frontend fqdn
fqdn=$(kubectl get gateway gateway-03 -n traffic-split -o jsonpath='{.status.addresses[0].value}')

# this curl command will return 50% of the responses from backend-v1
# and the remaining 50% of the responses from backend-v2
curl http://$fqdn  | jq '.pod'

# change http-route to v1: 10% and v2: 90% 
kubectl apply -f ./traffic-split/http-route-2.yaml

# this curl command will return 10% of the responses from backend-v1
# and the remaining 90% of the responses from backend-v2
curl http://$fqdn  | jq '.pod'
