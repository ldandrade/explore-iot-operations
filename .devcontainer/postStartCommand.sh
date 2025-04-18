#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# Setup environment
echo 'export CODESPACES="FALSE"' >> ~/.bashrc
echo 'export CLUSTER_NAME=${CODESPACE_NAME%-*}-codespace' >> ~/.bashrc
source ~/.bashrc

echo -e "Environment: \nSUBSCRIPTION_ID: $SUBSCRIPTION_ID \nRESOURCE_GROUP: $RESOURCE_GROUP \nLOCATION: $LOCATION \nCLUSTER_NAME: $CLUSTER_NAME"

az login --service-principal --username $CLIENT_ID --password $CLIENT_SECRET --tenant $TENANT_ID

az account set --subscription "$SUBSCRIPTION_ID"

# Run arcConnect.sh if not already connected
if ! az connectedk8s show --name "$CLUSTER_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
  echo "Running arcConnect.sh..."
  bash ./scripts/arcConnect.sh
else
  echo "Cluster '$CLUSTER_NAME' already connected to Azure Arc."
fi

# Run iotopsQuickstart.sh if needed (e.g., missing namespace or deployment)
if az iot ops show --cluster "$CLUSTER_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null && \
   kubectl get ns azure-iot-operations &>/dev/null; then
  echo "IoT Ops already fully provisioned (Azure + Kubernetes) for Cluster "$CLUSTER_NAME""
else
  echo "Running iotopsQuickstart.sh..."
  bash ./scripts/iotopsQuickstart.sh
fi

