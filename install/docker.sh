#!/bin/bash
# Install Docker (https://docs.docker.com/engine/install/ubuntu/)
SCRIPT_DIR="$(dirname $(realpath "${0}"))"
source "$SCRIPT_DIR/env"

docker(){
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
    add-apt-repository "deb [arch=arm64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io
    systemctl start docker
    systemctl enable docker
    usermod -aG docker "${DEFAULT_USER}"
}

install docker
