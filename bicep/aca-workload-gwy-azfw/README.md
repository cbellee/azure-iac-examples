# Azure Container Apps Private Preview example for UDR + Az Firewall + Application Gateway

### Pre-requisites
- Azure subscription (whitelisted for you subscription)
- Azure CLI
- Bash shell (WSL2)
- Public wild-card TLS certificate in .PFX format
- Public Azure DNS zone delgated from a public domain you own

### Deployment
- Create /.env file at the repo root containing the following environment variables
  - PUBLIC_CERT_PASSWORD='your PFX certificate secret'
  - ADMIN_GROUP_OBJECT_ID='your AAD AKS admin group name'
- Create a directory named 'certs' in the repo root 
  - add the TLS wild-card PFX certificate to the /certs directory
- Change current working directory to the repo root
- Change the following variables at the beginning of deploy.sh
  - DOMAIN_NAME='replace_with_your_public_domain_name'
  - PUBLIC_PFX_CERT_FILE="path/to/your/tls/certificate_name.pfx"
  - PUBLIC_DNS_ZONE_RESOURCE_GROUP='replace_with_the_name_of_the_resource_group_where_your_public_dns_zone_is_deployed'
- Run deploy.sh in the Bash shell
  - $ ./deploy.sh
