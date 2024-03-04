kubectl apply -f ../manifests/namspace.yaml

kubectl delete deploy order-api -n apis

TAG="acr5xaacqhgxhjqa.azurecr.io/order:dev-0.1.2"
sed "s|IMAGE_TAG|$TAG|g" ../manifests/order.yaml | kubectl apply -f -

kubectl delete deploy product-api -n apis

TAG="acr5xaacqhgxhjqa.azurecr.io/product:dev-0.1.2"
sed "s|IMAGE_TAG|$TAG|g" ../manifests/product.yaml | kubectl apply -f - 

kubectl delete deploy spa -n apis

TAG="acr5xaacqhgxhjqa.azurecr.io/spa:dev-0.1.2"
sed "s|IMAGE_TAG|$TAG|g" ../manifests/spa.yaml | kubectl apply -f - 
