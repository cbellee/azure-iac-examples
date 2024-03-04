# generate .pfx files
openssl pkcs12 -export -out apicert.pfx -inkey ./certs/api.kainiindustries.net/private.key -in ./certs/api.kainiindustries.net/certificate.crt
openssl pkcs12 -export -out portalcert.pfx -inkey ./certs/portal.kainiindustries.net/private.key -in ./certs/portal.kainiindustries.net/certificate.crt

# generate .cer files
openssl x509 -inform pem -in ./certs/api.kainiindustries.net/certificate.crt -outform der -out ./certs/api.kainiindustries.net/apicert.cer
openssl x509 -inform pem -in ./certs/portal.kainiindustries.net/certificate.crt -outform der -out ./certs/portal.kainiindustries.net/portalcert.cer

