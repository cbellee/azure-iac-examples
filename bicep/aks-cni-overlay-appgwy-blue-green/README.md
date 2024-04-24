# Application Gateway routing to in-cluster NGINX Ingress Controller for Blue Green Deployment

## pre-requisites

- Azure subscription
- Azure CLI
- Bash shell
- SSH Public key - `~/.ssh/id_rsa.pub`

## deployment steps

- Run `$ ./deploy.sh` to deploy the resources

## blue/green testing steps

- Log onto the Linux VM via Azure Bastion Host, supplying the userName `localadmin` and the SSH private key file `~/.ssh/id_rsa`
- run `$ curl http://gateway.test.internal` - you should receive the 'Blue' page HTML
- In the Azure portal, change the App Gateway rule to point to the 'green-pool' backend pool.
- Next, run `$ curl http://gateway.test.internal` again - you should now receive the 'Green' page HTML
