# delete secret
kubectl delete secret aks-ingress-tls

# create tls secret
kubectl create secret tls aks-ingress-tls \
--key ./certs/private.key \
--cert ./certs/certificate.crt 