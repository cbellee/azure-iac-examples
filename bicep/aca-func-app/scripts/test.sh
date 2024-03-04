RG_NAME='aca-func-go-rg'
ACA_APP_URL=$(az containerapp list -g $RG_NAME --query '[].properties.configuration.ingress.fqdn' -o tsv)

curl "https://$ACA_APP_URL/api/todos" | jq # list all todos - should return an empty array

curl "https://$ACA_APP_URL/api/todos" -X POST -d '{"description":"get some cat food"}'
curl "https://$ACA_APP_URL/api/todos" -X POST -d '{"description":"get some dog food"}'
curl "https://$ACA_APP_URL/api/todos" -X POST -d '{"description":"get some milk"}'
curl "https://$ACA_APP_URL/api/todos" -X POST -d '{"description":"get some bread"}'

curl "https://$ACA_APP_URL/api/todos" | jq # list all todos
curl "https://$ACA_APP_URL/api/todos/complete/1" -X PATCH # complete todo
curl "https://$ACA_APP_URL/api/todos/completed" | jq # list todos
curl "https://$ACA_APP_URL/api/todos/incomplete" | jq # list todos
curl "https://$ACA_APP_URL/api/todos/2" -X PATCH -d '{"description":"get some fish food"}' # update todo
curl "https://$ACA_APP_URL/api/todos" | jq # list all todos


