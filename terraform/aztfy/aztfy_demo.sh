# install Terraform
# https://learn.hashicorp.com/tutorials/terraform/install-cli

# install AzTfy
# https://github.com/Azure/aztfy

# set Azure subscription & resource group
AZTFY_SUBSCRIPTION_ID=$(az account show --query id -o tsv)
RG_NAME="aztfydemo-rg"

# create output directory
mkdir ./output -p

# run aztfy against resource group
aztfy --output-dir ./output $RG_NAME

# 'skipped' resources need to have the type and name specified, e.g.
# azurerm_kubernetes_cluster.myaks