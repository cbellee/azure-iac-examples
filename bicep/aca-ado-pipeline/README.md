# Azure Container App Deployment pipeline example

## Overview

This example demonstrates how to deploy a containerized application to Azure Container Apps using Azure DevOps. The pipeline consists of a parent './pipelines/main.yaml' template which executes three child templates describe below.

- ./pipelines/infra_deploy.yaml
  - This template creates the Azure Container Apps infrastructure using Azure Bicep templates
- ./pipelines/templates/app_build.yaml
  - This template builds the container image and pushes it to Azure Container Registry.
- ./pipelines/templates/app_deploy.yaml
  - This template deploys the containerized application to Azure Container Apps.

## Prerequisites

- Azure subscription.
  - If you don't have an Azure subscription, create a [free account](https://azure.microsoft.com/free/?ref=microsoft.com&utm_source=microsoft.com&utm_medium=docs&utm_campaign=visualstudio) before you begin.
- Azure DevOps organization.
  - If you don't have an organization, you can sign up for free at [Azure DevOps](https://dev.azure.com/?WT.mc_id=DOP-MVP-5001511).
- Azure DevOps service connection.
  - Create a service connection to your Azure subscription. For more information, see [Create an Azure service connection](https://go.microsoft.com/fwlink/?LinkId=623000).
  - Ensure the service connection has the 'Owner' RBAC role assigned at the subscription level. Ideally, use the Federated Identity option for the service connection type (the current default option in the Azure DevOps UI).

## Setup

- Fork this repository to your Azure DevOps organization. This will create a copy of the repository in your organization.
- Create a new pipeline in Azure DevOps and select the 'Azure Repos Git' option.
- Select the repository you forked in the previous step.
- Select the 'Existing Azure Pipelines YAML file' option and choose the './main.yaml' file from the repository.
- Review the pipeline and click 'Run' to execute it.
