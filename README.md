# Explore IoT Operations

This further extends the [Explore IoT Operations](https://github.com/Azure-Samples/explore-iot-operations) repo to evaluate integration capabilities with other IoT Platforms such as EMQx.

## Features

This project provides the following:

* Pre-configured codespace with [K3s](https://k3s.io/) cluster via [K3d](https://k3d.io/)
* EMQX MQTT Broker running as a pod within K3D
* AIO MQTT Broker running as a pod within K3D
* MQTT Bridge configured from EMQX to AIO for message forwarding
* MQTT Device Simulator for publishing and subscribing to topics
* HTTP & GRPC Callout Server

## Getting Started

1. Use this GitHub codespace to explore Azure IoT Operations in your browser without installing anything on your local machine.

   [![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/ldandrade/explore-iot-operations?quickstart=1)

1. (Optional) Enter your Azure details to store them as environment variables inside the codespace.

1. **Important**: Open the codespace in VS Code Desktop with **Ctrl/Cmd + Shift + P** > **Codespaces: Open in VS Code Desktop**. This is required to login to Azure CLI properly.

1. Connect your new cluster to Azure Arc.

   ```bash
   az login
   az account set -s $SUBSCRIPTION_ID
   az connectedk8s connect -n $CLUSTER_NAME -g $RESOURCE_GROUP -l $LOCATION
   ```

1. Follow [Azure IoT Operations docs](https://learn.microsoft.com/azure/iot-operations/get-started/quickstart-deploy?tabs=codespaces) to finish deploying.

1. Run the following commands inside Codespaces to deploy EMQX:
   ```bash
   kubectl apply -f k8s/emqx/emqx-deployment.yaml
   kubectl apply -f k8s/emqx/emqx-service.yaml
   ```

1. Check that EMQX is running:
   ```bash
   kubectl get pods -l app=emqx
   kubectl get svc emqx-service
   ```

1. Port-forward the EMQX Dashboard by running the following command:
   ```bash
   kubectl port-forward <emqx-pod-name> 18083:18083
   ```


## Trademark Notice

Trademarks This project may contain trademarks or logos for projects, products, or services. Authorized use of Microsoft trademarks or logos is subject to and must follow [Microsoft’s Trademark & Brand Guidelines](https://www.microsoft.com/legal/intellectualproperty/trademarks/usage/general). Use of Microsoft trademarks or logos in modified versions of this project must not cause confusion or imply Microsoft sponsorship. Any use of third-party trademarks or logos are subject to those third-party’s policies.