#!/bin/sh

set -o errexit
set -o nounset
set -o pipefail

echo "Starting On Create Command"

# Copy the custom first-run notice over
sudo cp .devcontainer/welcome.txt /usr/local/etc/vscode-dev-containers/first-run-notice.txt

# Check if $CLUSTER_NAME is set, otherwise default to "k3s-default"
if [ -z "$CLUSTER_NAME" ]; then
  CLUSTER_NAME="k3s-default"
  echo "No cluster name provided, defaulting to $CLUSTER_NAME"
fi

# Delete existing cluster and recreate it
k3d cluster delete || echo "No cluster found to delete"

# Create the cluster with corrected port mappings
k3d cluster create "$CLUSTER_NAME" \
-p "1883:1883@loadbalancer" \  # AIO MQTT Broker
-p "8883:8883@loadbalancer" \  # AIO Secure MQTT Broker
-p "1884:1884@loadbalancer" \  # EMQX MQTT Broker (NEW)
-p "8884:8884@loadbalancer" \  # EMQX Secure MQTT Broker (NEW)
-p "18084:18083@loadbalancer"  # EMQX Dashboard (NEW)

echo "Ending On Create Command"
