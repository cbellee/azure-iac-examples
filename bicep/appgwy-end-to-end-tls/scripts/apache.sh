sudo apt update -y
sudo apt upgrade -y
sudo apt install apache2 -y

sudo cp /var/lib/waagent/Microsoft.Azure.KeyVault/ca.crt /etc/ssl/certs/
sudo cp /var/lib/waagent/Microsoft.Azure.KeyVault/cert.pem /etc/ssl/
sudo cp /var/lib/waagent/Microsoft.Azure.KeyVault/key.pem /etc/ssl/private/

sudo a2enmod ssl
sudo a2ensite default-ssl
sudo systemctl reload apache2
