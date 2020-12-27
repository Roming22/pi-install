#!/bin/bash
# Install k3d
SCRIPT_DIR="$(dirname $(realpath "${0}"))"
source "$SCRIPT_DIR/env"

k3d(){
    snap install kubectl --classic
    su "${DEFAULT_USER}" -c "bash -c configure"
}

configure(){
    curl -s https://raw.githubusercontent.com/rancher/k3d/main/install.sh | bash
    # Use the latest image, as 1.18 does not support a reboot
    k3d cluster create "$USER" --image rancher/k3s:latest
    k3d kubeconfig merge "$USER" --switch-context
    kubectl get all --all-namespaces
}
export -f configure

install k3d
