# Bicep Deployment Script

This repository contains a script to deploy a Azure Container App in combination with a Azure Monitor to consolidate logging.

## Prerequisites

- Azure CLI installed
- Proper Azure subscription access
- Bicep template and parameter files

## Usage

Set the following environment variables and run the deployment command:

```shell
export RESOURCE_GROUP="mvploggingissue"
export BICEP_TEMPLATE="./main.bicep"
export BICEP_PARAMS="./your_params_file.bicepparam"
export LOCATION="centralus"

az deployment sub create --location="$LOCATION" --template-file "$BICEP_TEMPLATE" --parameters "$BICEP_PARAMS"