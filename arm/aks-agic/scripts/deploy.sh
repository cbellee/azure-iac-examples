# install pod identity
kubectl create -f https://raw.githubusercontent.com/Azure/aad-pod-identity/master/deploy/infra/deployment-rbac.yaml

# set up helm with rbac
kubectl create serviceaccount --namespace kube-system tiller-sa
kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller-sa
helm init --tiller-namespace kube-system --service-account tiller-sa
helm repo add application-gateway-kubernetes-ingress https://azure.github.io/application-gateway-kubernetes-ingress/helm/
helm repo update

# edit helm-config.yaml

# install app gwy ingress
helm install -f helm-config.yaml application-gateway-kubernetes-ingress/ingress-azure

# deploy guestbook app
kubectl apply -f guestbook-all-in-one.yaml

# deploy http ingress
# kubectl apply -f ingress-guestbook-http.yaml

# create TLS cert
kubectl create secret tls guestbook-tls-secret --key ./certs/private.key --cert ./certs/certificate.crt

# add TLS ingress path
kubectl apply -f ingress-guestbook-tls-sni.yaml