# root certificate
openssl ecparam -out ../certs/root.key -name prime256v1 -genkey
openssl req -new -sha256 -key ../certs/root.key -out ../certs/root.csr -subj "/C=AU/ST=NSW/L=Sydney/O=IT/CN=kainiindustries.net"
openssl x509 -req -sha256 -days 365 -in ../certs/root.csr -signkey ../certs/root.key -out ../certs/root.crt

# client certificate
openssl ecparam -out ../certs/client.key -name prime256v1 -genkey
openssl req -new -sha256 -key ../certs/client.key -out ../certs/client.csr -subj "/C=AU/ST=NSW/L=Sydney/O=IT/CN=myapp.kainiindustries.net"
openssl x509 -req -in ../certs/client.csr -CA ../certs/root.crt -CAkey ../certs/root.key -CAcreateserial -out ../certs/client.crt -days 365 -sha256 
openssl x509 -in ../certs/client.crt -text -noout
openssl pkcs12 -export -out ../certs/client.pfx -inkey ../certs/client.key -in ../certs/client.crt
openssl base64 -in ../certs/client.pfx -out ../certs/clientbase64