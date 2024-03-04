# bicep build ./main.bicep

az group create --name tac-test-rg --location australiaeast
az deployment group create --template-file ./main.bicep --resource-group tac-test-rg
