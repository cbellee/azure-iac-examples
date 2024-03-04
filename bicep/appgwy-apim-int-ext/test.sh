URL=https://api.kainiindustries.net/external

# create #1, #2, #3
curl $URL/api/todos --insecure -X POST -d '{"description":"first todo item"}'
curl $URL/api/todos --insecure -X POST -d '{"description":"second todo item"}'
curl $URL/api/todos --insecure -X POST -d '{"description":"third todo item"}'
curl $URL/api/todos --insecure -X POST -d '{"description":"fourth todo item"}'

# update
curl $URL/api/todos/1 --insecure -X PATCH -d '{"description":"really the first todo item"}'

# list all
curl $URL/api/todos --insecure

# complete #3
curl $URL/api/todos/complete/3 --insecure -X PATCH

# list completed
curl $URL/api/todos/completed --insecure

# list incomplete
curl $URL/api/todos/incomplete --insecure

#delete #2
curl $URL/api/todos/4 --insecure -X DELETE -d '{}'

# list all
curl $URL/api/todos --insecure

