# Azure Container App with internal load balancer

## prerequisites

- Azure CLI
- Azure Subscription
- Bash shell
- SSH key pair in ~/.ssh directory name id_rsa.pub and id_rsa

## deployment steps

- Clone the repository
- Execute the following command

```bash
./deploy.sh
```

- once complete, your shell will SSH into the VM and you can run the following command to test the DNS resolution & container app

```bash
nslookup <APP_FQDN>
curl https://<APP_FQDN>
```
