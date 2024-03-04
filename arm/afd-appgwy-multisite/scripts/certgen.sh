# generate .pfx files
openssl pkcs12 -export -out ../certs/kainiindustries.pfx -inkey ../certs/private.key -in ../certs/certificate.crt

# generate .cer files
openssl x509 -inform pem -in ../certs/certificate.crt -outform der -out ../certs/kainiindustries.cert.cer


