FROM mcr.microsoft.com/devcontainers/universal:2-linux

# Install mosquitto client
RUN apt-get update && apt-get install -y mosquitto-clients

# Install Step CLI
RUN wget https://dl.smallstep.com/gh-release/cli/docs-cli-install/v0.23.4/step-cli_0.23.4_amd64.deb && \
    sudo dpkg -i step-cli_0.23.4_amd64.deb && \
    rm ./step-cli_0.23.4_amd64.deb

# Install Dapr CLI
RUN wget -q https://raw.githubusercontent.com/dapr/cli/master/install/install.sh -O - | /bin/bash

# Install mqttui
RUN wget https://github.com/EdJoPaTo/mqttui/releases/download/v0.21.1/mqttui-v0.21.1-x86_64-unknown-linux-gnu.deb && \
    sudo apt-get install -y ./mqttui-v0.21.1-x86_64-unknown-linux-gnu.deb && \
    rm -rf ./mqttui-v0.21.1-x86_64-unknown-linux-gnu.deb

# Install k9s
RUN wget https://github.com/derailed/k9s/releases/download/v0.28.0/k9s_Linux_amd64.tar.gz && \
    tar xf k9s_Linux_amd64.tar.gz --directory=/usr/local/bin k9s && \
    chmod +x /usr/local/bin/k9s && \
    rm -rf k9s_Linux_amd64.tar.gz

# Install and configure EMQx
RUN wget https://www.emqx.com/en/downloads/broker/5.8.6/emqx-5.8.6-ubuntu24.04-amd64.tar.gz && \
    tar -xzf emqx-5.8.6-ubuntu24.04-amd64.tar.gz -C /opt/ && \
    rm emqx-5.8.6-ubuntu24.04-amd64.tar.gz

ENV EMQX_HOME=/opt/emqx
ENV PATH="$EMQX_HOME/bin:$PATH"

# Copy EMQx bridge config for Azure IoT Operations
# COPY emqx_bridge.conf /opt/emqx/etc/emqx_bridge.conf

# Expose necessary ports (avoid 1883 to prevent conflict)
EXPOSE 1884 8883 8083 8084 18083

# Start EMQx
CMD ["/opt/emqx/bin/emqx", "start"]
