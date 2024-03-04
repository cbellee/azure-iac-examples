# Azure Application Gateway v2 multi-site listener 

## Description
Example ARM templates and YAML Azure DevOps pipeline to deploy Azure Application Gateway with subdomain multisite listeners for Azure App Service containers.

For example

- front-end.contoso.com
- back-end.contoso.com

## Usage

- Fork or clone this repo.
- Create a new Azure DevOps pipeline and import the existing azure-pipelines.yaml file at the repo's root.
- Create the following pipeline variables either directly in the .yaml file variables: section or in the GUI
  - base64EncodedPfxCertificate -> base64 encoded pfx certificate string for root DNS zone name, usually a wildcard certificate (e.g. *.contoso.com)
  - base64EncodedPfxCertificatePassword -> certificate password string
  - serviceConnection -> name of Azure service connection
  - dnsZoneResourceGroupName -> resource group name of existing Azure DNS zone containing customer owned DNS zone
  - dnsZoneName -> name of dns zone (e.g. contoso.com)
