#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# Function to print in green
print_green() {
    echo -e "\033[32m$1\033[0m"
}

echo -e "\n--- [arcConnect.sh] Starting Azure Arc connection setup ---"

# Ensure Azure CLI is logged in
if ! az account show &>/dev/null; then
    echo -e "\nError: Azure CLI is not logged in. Run 'az login' manually or use a credentialed Codespace."
    exit 1
fi

# Set Azure subscription (if not already)
CURRENT_SUBSCRIPTION=$(az account show --query id -o tsv)
if [[ "$CURRENT_SUBSCRIPTION" != "$SUBSCRIPTION_ID" ]]; then
    echo "Setting Azure subscription to: $SUBSCRIPTION_ID"
    az account set --subscription "$SUBSCRIPTION_ID"
fi

# Validate location
SUPPORTED_LOCATIONS=("eastus" "eastus2" "westus2" "westus3" "westeurope" "northeurope")
if [[ ! " ${SUPPORTED_LOCATIONS[*]} " =~ " ${LOCATION} " ]]; then
    echo -e "\nError: Location $LOCATION is not in the supported list: ${SUPPORTED_LOCATIONS[*]}"
    exit 1
fi

# Ensure resource group exists
if ! az group show --name "$RESOURCE_GROUP" &>/dev/null; then
    echo "Creating resource group: $RESOURCE_GROUP in $LOCATION"
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output table
else
    echo "Using existing resource group: $RESOURCE_GROUP"
fi

# Set cluster name
CLUSTER_NAME="${CLUSTER_NAME:-iotops-quickstart-cluster}"

# Check if cluster is already connected
if az connectedk8s show --name "$CLUSTER_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    echo "Cluster '$CLUSTER_NAME' is already connected to Azure Arc."
    exit 0
fi

# Add Azure Arc extension if not present
if ! az extension show --name connectedk8s &>/dev/null; then
    echo "Installing Azure CLI extension: connectedk8s"
    az extension add --name connectedk8s
fi

# Connect to Azure Arc
echo "Connecting Kubernetes cluster '$CLUSTER_NAME' to Azure Arc..."
az connectedk8s connect --name "$CLUSTER_NAME" --resource-group "$RESOURCE_GROUP"

# Output environment vars
SCRIPT_DIR="$(dirname "$0")"
echo "Saving connection environment variables to $SCRIPT_DIR/env_vars.txt"

cat <<EOL > "$SCRIPT_DIR/env_vars.txt"
export CLUSTER_NAME=$CLUSTER_NAME
export RESOURCE_GROUP=$RESOURCE_GROUP
export LOCATION=$LOCATION
EOL

echo -e "\n✅ Azure Arc connection complete."
echo -e "Run \033[32msource $SCRIPT_DIR/env_vars.txt\033[0m to re-export environment variables later."
