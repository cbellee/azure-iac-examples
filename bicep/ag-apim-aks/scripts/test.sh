# this should fail with 'Access Denied' error

curl -k https://api.aksdemo.kainiindustries.net/api/order/orders
curl -k https://api.aksdemo.kainiindustries.net/api/product/products






curl -k -X POST -H "Content-Type: application/json" https://api.aksdemo.kainiindustries.net/api/product/products -d '{"Name":"Product A","Description":"This is product A"}'
curl -k -X POST -H "Content-Type: application/json" https://api.aksdemo.kainiindustries.net/api/product/products -d '{"Name":"Product B","Description":"This is product B"}'
curl -k -X POST -H "Content-Type: application/json" https://api.aksdemo.kainiindustries.net/api/product/products -d '{"Name":"Product C","Description":"This is product C"}'

curl -k -X POST curl -k -H "Content-Type: application/json" https://api.aksdemo.kainiindustries.net/api/order/orders -d '{"Name":"Order 1","Description":"This is order 1"}'
curl -k -X POST curl -k -H "Content-Type: application/json" https://api.aksdemo.kainiindustries.net/api/order/orders -d '{"Name":"Order 2","Description":"This is order 2"}'
curl -k -X POST curl -k -H "Content-Type: application/json" https://api.aksdemo.kainiindustries.net/api/order/orders -d '{"Name":"Order 3","Description":"This is order 3"}'

curl -k -X DELETE https://api.aksdemo.kainiindustries.net/api/order/orders/1000
curl -k -X DELETE https://api.aksdemo.kainiindustries.net/api/order-api/orders/1001
curl -k -X DELETE https://api.aksdemo.kainiindustries.net/api/order-api/orders/1002

curl -k -X DELETE https://api.aksdemo.kainiindustries.net/api/product/products/1000
curl -k -X DELETE https://api.aksdemo.kainiindustries.net/api/product/products/1001
curl -k -X DELETE https://api.aksdemo.kainiindustries.net/api/product/products/1002