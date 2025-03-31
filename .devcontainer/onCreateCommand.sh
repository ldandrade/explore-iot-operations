#!/bin/sh

set -o errexit
set -o nounset
set -o pipefail

echo "Starting On Create Command"

# Copy the custom first-run notice over
sudo cp .devcontainer/welcome.txt /usr/local/etc/vscode-dev-containers/first-run-notice.txt

# Delete existing cluster and recreate it
k3d cluster delete
k3d cluster create \
-p '1883:1883@loadbalancer' \  # AIO MQTT Broker
-p '8883:8883@loadbalancer' \  # AIO Secure MQTT Broker
-p '1884:1884@loadbalancer' \  # EMQX MQTT Broker (NEW)
-p '8884:8884@loadbalancer' \  # EMQX Secure MQTT Broker (NEW)
-p '18084:18083@loadbalancer'  # EMQX Dashboard (NEW)

echo "Ending On Create Command"
