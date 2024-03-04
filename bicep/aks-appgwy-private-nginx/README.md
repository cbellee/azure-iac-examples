# End to end encryption in transit for Azure Kubernetes Service
## Application Gateway <-TLS-> NGINX Ingress (private IP) <-mTLS-> Open Service Mesh 

A demonstration of how to configure a secure ingress path from Azure Application Gateway to a pod running in AKS as part of an OSM service mesh.

## Prerequisites

- Bash shell (Linux, Windows Subsystem for Linux, MacOS, etc.)
- Azure subscription
- Install [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
- Install [Openssl](https://www.openssl.org/)
- A valid Public TLS certificate in .PFX format
- A local SSH public key (~/.ssh/id_rsa.pub)
- [Kubectl CLI](https://kubernetes.io/docs/tasks/tools/)
- [Helm CLI](https://helm.sh/docs/intro/install/)
- [jq](https://stedolan.github.io/jq/download/)

## Install

- Place your public TLS PFX certificate in new directory in the repo root folder named `certs`
- Create a local .env file with the following variables
  
    ```bash
      PUBLIC_CERT_PASSWORD='your_password' # password required to import public PFX certificate into Azure Key Vault
      PRIVATE_CERT_PASSWORD='your_password' # password required to import private PFX certificate into Azure Key Vault
      ADMIN_GROUP_OBJECT_ID='your_AAD_admin_group_objectId' # AAD group for AKS Cluster Admin role permissions (add your account to this group)
    ```

- Modify the following varialbes in the ./deploy.sh script
  - Public TLS certificate name/path
  - Domain name
  - Resource group name where your public Azure DNS zone resides

    ```bash
      DOMAIN_NAME='your_public_domain_name'
      PUBLIC_PFX_CERT_FILE='./certs/your_public_domain_tls_pfx_certificate.pfx'
      PUBLIC_DNS_ZONE_RG_NAME='your_Azure_public_dns_zone_resource_group_name'
    ```

- Run the install script

    ```bash
      ./deploy.sh
    ```
