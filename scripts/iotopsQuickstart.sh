#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

# Print in green
print_green() {
    echo -e "\033[32m$1\033[0m"
}

echo -e "\n--- [iotopsQuickstart.sh] Starting IoT Ops environment setup ---"

# Validate required env vars
for var in SUBSCRIPTION_ID RESOURCE_GROUP LOCATION CLUSTER_NAME; do
  if [ -z "${!var:-}" ]; then
    echo "Error: Environment variable '$var' is not set."
    exit 1
  fi
done

az login --identity

# Set subscription
az account set --subscription "$SUBSCRIPTION_ID"

# Ensure resource group
if ! az group show --name "$RESOURCE_GROUP" &>/dev/null; then
    echo "Creating resource group: $RESOURCE_GROUP"
    az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output none
else
    echo "Using existing resource group: $RESOURCE_GROUP"
fi

# Ensure Azure Arc connection
if ! az connectedk8s show --name "$CLUSTER_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    echo "Connecting cluster '$CLUSTER_NAME' to Azure Arc"
    az connectedk8s connect --name "$CLUSTER_NAME" --resource-group "$RESOURCE_GROUP"
else
    echo "Cluster '$CLUSTER_NAME' already connected to Azure Arc"
fi

# Derive unique names
UNIQUE_SUFFIX=$(echo "$RESOURCE_GROUP" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]')
UNIQUE_SUFFIX=${UNIQUE_SUFFIX:0:18}
STORAGE_ACCOUNT="st${UNIQUE_SUFFIX:0:24}"
SCHEMA_REGISTRY="sr${UNIQUE_SUFFIX}"
SCHEMA_REGISTRY_NAMESPACE="srn${UNIQUE_SUFFIX}"

# Create storage account
if ! az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    echo "Creating storage account: $STORAGE_ACCOUNT"
    az storage account create \
        --name "$STORAGE_ACCOUNT" \
        --location "$LOCATION" \
        --resource-group "$RESOURCE_GROUP" \
        --enable-hierarchical-namespace true \
        --sku Standard_RAGRS \
        --kind StorageV2 \
        --output none
else
    echo "Storage account '$STORAGE_ACCOUNT' already exists"
fi

# Get storage account ID
SA_RESOURCE_ID=$(az storage account show --name "$STORAGE_ACCOUNT" --resource-group "$RESOURCE_GROUP" --query id -o tsv)

# Create schema registry
if ! az iot ops schema registry show --name "$SCHEMA_REGISTRY" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    echo "Creating schema registry: $SCHEMA_REGISTRY"
    az iot ops schema registry create \
        --name "$SCHEMA_REGISTRY" \
        --resource-group "$RESOURCE_GROUP" \
        --registry-namespace "$SCHEMA_REGISTRY_NAMESPACE" \
        --sa-resource-id "$SA_RESOURCE_ID" \
        --output none
else
    echo "Schema registry '$SCHEMA_REGISTRY' already exists"
fi

SR_RESOURCE_ID=$(az iot ops schema registry show --name "$SCHEMA_REGISTRY" --resource-group "$RESOURCE_GROUP" --query id -o tsv)

# Initialize IoT Ops
if ! az iot ops show --cluster "$CLUSTER_NAME" --resource-group "$RESOURCE_GROUP" &>/dev/null; then
    echo "Initializing IoT Operations on cluster: $CLUSTER_NAME"
    az iot ops init --cluster "$CLUSTER_NAME" --resource-group "$RESOURCE_GROUP"
else
    echo "IoT Operations already initialized"
fi

# Create IoT Ops instance
INSTANCE_NAME="${CLUSTER_NAME}-instance"
if ! az iot ops show --cluster "$CLUSTER_NAME" --resource-group "$RESOURCE_GROUP" --name "$INSTANCE_NAME" &>/dev/null; then
    echo "Creating IoT Operations instance: $INSTANCE_NAME"
    az iot ops create \
        --cluster "$CLUSTER_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --name "$INSTANCE_NAME" \
        --sr-resource-id "$SR_RESOURCE_ID" \
        --broker-frontend-replicas 1 \
        --broker-frontend-workers 1 \
        --broker-backend-part 1 \
        --broker-backend-workers 1 \
        --broker-backend-rf 2 \
        --broker-mem-profile Low \
        --output none
else
    echo "IoT Operations instance '$INSTANCE_NAME' already exists"
fi

# Save variables
SCRIPT_DIR="$(dirname "$0")"
ENV_VARS_FILE="$SCRIPT_DIR/env_vars.txt"
echo "Saving environment variables to $ENV_VARS_FILE"
cat <<EOL > "$ENV_VARS_FILE"
export CLUSTER_NAME="$CLUSTER_NAME"
export RESOURCE_GROUP="$RESOURCE_GROUP"
export LOCATION="$LOCATION"
export UNIQUE_SUFFIX="$UNIQUE_SUFFIX"
export STORAGE_ACCOUNT="$STORAGE_ACCOUNT"
export SA_RESOURCE_ID="$SA_RESOURCE_ID"
export SCHEMA_REGISTRY="$SCHEMA_REGISTRY"
export SCHEMA_REGISTRY_NAMESPACE="$SCHEMA_REGISTRY_NAMESPACE"
export SR_RESOURCE_ID="$SR_RESOURCE_ID"
export INSTANCE_NAME="$INSTANCE_NAME"
EOL

echo -e "\n$(print_green '✅ IoT Operations setup completed successfully!')"
echo "To export these variables later, run: $(print_green "source $ENV_VARS_FILE")"
