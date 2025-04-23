#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# Function to print in green
print_green() {
    echo -e "\033[32m$1\033[0m"
}

echo -e "\n--- [arcConnect.sh] Starting Azure Arc connection setup ---"

az login --service-principal --username $CLIENT_ID --password $CLIENT_SECRET --tenant $TENANT_ID

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

# Ensure required Azure resource providers are registered
required_providers=("Microsoft.ExtendedLocation" "Microsoft.Kubernetes" "Microsoft.KubernetesConfiguration" "Microsoft.IoTOperations" "Microsoft.DeviceRegistry" "Microsoft.SecretSyncController")

for provider in "${required_providers[@]}"; do
    registration_state=$(az provider show -n "$provider" --query "registrationState" -o tsv)
    if [[ "$registration_state" != "Registered" ]]; then
        echo "Registering resource provider: $provider"
        az provider register -n "$provider"
        echo "Waiting for $provider to be registered..."
        while [[ $(az provider show -n "$provider" --query "registrationState" -o tsv) != "Registered" ]]; do
            sleep 10
        done
        echo "$provider is registered."
    else
        echo "$provider is already registered."
    fi
done

# Check if the service principal has sufficient permissions
echo "Validating service principal permissions..."
sp_check=$(az role assignment list --assignee $CLIENT_ID --query "[?roleDefinitionName=='Contributor']" -o tsv)
if [[ -z "$sp_check" ]]; then
    echo "Error: Service principal does not have sufficient permissions. Assign the 'Contributor' role."
    exit 1
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