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
k3d cluster create "$CLUSTER_NAME" -p "1883:1883@loadbalancer" -p "8883:8883@loadbalancer" -p "1884:1884@loadbalancer" -p "8884:8884@loadbalancer" -p "18084:18083@loadbalancer"
# AIO MQTT Broker 1883
# AIO Secure MQTT Broker 8883
# EMQX MQTT Broker (NEW) 1884
# EMQX Secure MQTT Broker (NEW) 8884
# EMQX Dashboard (NEW) 18084

echo "Ending On Create Command"
