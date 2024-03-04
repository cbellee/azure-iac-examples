# AKS NGINX ingress with Azure KeyVault Provider and secrets store driver, using Workload Identity federation

This sample shows how to use the [Azure Key Vault Provider for Secrets Store CSI Driver](https://github.com/Azure/secrets-store-csi-driver-provider-azure) with [Workload Identity federation](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity) on [Azure Kubernetes Service (AKS)](https://docs.microsoft.com/azure/aks/).

## Prerequisites

- Azure subscription
- Azure CLI version 2.55 or later
- SSH public key in ~/.ssh/id_rsa.pub
- set the following line in ./.env
`ADMIN_GROUP_OBJECT_ID=<your AAD AKS Admin Group Object ID>`

## Setup

- run ./deploy.sh

## Test

- Copy public certificate to trusted certificate store on linux jumpbox

```bash
rm ./cert.crt
az keyvault certificate download --vault-name $KV_NAME -n $CERT_NAME -f cert.crt -e PEM && /

VM_PUBLIC_IP_ADDRESS=$(az vm list-ip-addresses -g $RG_NAME --query [].virtualMachine.network.publicIpAddresses[0].ipAddress -o tsv)
scp ./cert.crt localadmin@$VM_PUBLIC_IP_ADDRESS:/tmp
```

- SSH to vm jumpbox

```bash
ssh localadmin@$VM_PUBLIC_IP_ADDRESS
```

- Run the following commands in the ssh session to add the self-signed certificate to the vm ca-certificate store, so that we don't need to use curl's '-k' flag to ignore TLS validation errors

```bash
# copy the certificate from /tmp to the trusted certificate store
sudo cp /tmp/cert.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

# test the ingress controller using curl
curl https://demo.azure.com/hello-world --resolve demo.azure.com:443:10.0.16.4 -v
```
