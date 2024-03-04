# initialise Terraform storage & providers
# NOTE: in a real-world dpeloyment the state file would be stored in an Azure storage blob
terraform init

# plan 'dev' environment
terraform plan -var-file=./environments/dev.tfvars -out=./dev-plan

# apply 'dev' environment
terraform apply -auto-approve ./dev-plan

# delete 'dev' environment
terraform apply -var-file=./environments/dev.tfvars -destroy

# plan 'prod' environment
terraform plan -var-file=./environments/prod.tfvars -out=./prod-plan

# apply 'prod' environment
terraform apply -auto-approve ./prod-plan

# delete 'prod' environment
terraform apply -var-file=./environments/prod.tfvars -destroy
