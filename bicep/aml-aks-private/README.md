# Secure Azure Machine Learning Workspace Deployment

## Prerequisites
- install [azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt)

## Deployment steps
- create `.env` file in `/aml-aks-private` with the following two variable declarations on separate lines. 
  - data science vm password
  - `DS_VM_PASSWORD='<your vm password>'`
  - JSON array of group objectIds containing user accounts to be granted full RBAC access to the AKS cluster.
  - `ADMIN_GROUP_OBJECT_IDS="['<your group object id>']"`
- execute the deployment script
  - `$ ./deploy.sh`
