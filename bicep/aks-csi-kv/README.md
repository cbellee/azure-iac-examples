# AKS CSI driver for Keyvault  with multiple User Managed Identities & Keyvaults
This example demonstrates how to use the AKS CSI driver for KeyVault to allow pods in two different namespaces to read secrets from two key vaults using two different managed identities.

## Pre-requisites
- Bash shell
- [yq](https://github.com/mikefarah/yq/releases/tag/v4.25.3)
- [kubectl](https://kubernetes.io/docs/tasks/tools/)

## Install
- Execute  `./deploy.sh` to create:
  - 1 AKS cluster
  - 2 Key Vaults
  - 2 User Managed Identities (1 per key vault)
  - 2 secrets (1 per key vault)
  - Deploy the CSI driver addon
  - 2 namespaces
  - Generate & apply 2 SecretProviderClass manifests 
      - each object associates one user managed identity with one of the key vaults
  - Generate & apply 2 example pod manifests 
      - each pod uses one SecretProviderClass object to obtain a secret from one of the key vaults
