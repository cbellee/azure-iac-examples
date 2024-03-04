export AZURE_CLIENT_ID=$(cat ./app.json | jq '.appId' -r)
export AZURE_CLIENT_SECRET=$(cat ./app.json | jq '.password' -r)
export AZURE_TENANT_ID=$(cat ./app.json | jq '.tenant' -r)
export AZURE_SUBSCRIPTION_ID=$(az account show --query id -o tsv)

:'
AMQP	5671, 5672	AMQP with TLS. See AMQP protocol guide
HTTPS	443	This port is used for the HTTP/REST API and for AMQP-over-WebSockets
'
