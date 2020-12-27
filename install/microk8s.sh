#!/bin/bash
# Install microk8s
SCRIPT_DIR="$(dirname $(realpath "${0}"))"
source "$SCRIPT_DIR/env"

microk8s(){
    snap install microk8s --classic
    ufw allow in on cni0
    ufw allow out on cni0
    ufw default allow routed

    # Configure default user
    usermod -a -G microk8s "${DEFAULT_USER}"
    chown -f -R "${DEFAULT_USER}" ~/.kube
    su "${DEFAULT_USER}" -c "bash -c configure"
}

configure(){
    # Create alias
    mkdir -p "$HOME/bin"
    KUBECTL="microk8s kubectl"
    echo "${KUBECTL} \$*" > "$HOME/bin/kubectl"
    chmod +x "$HOME/bin/kubectl"

    # Setup the cluster
    microk8s status --wait-ready
    microk8s enable dns dashboard storage
    $KUBECTL get all --all-namespaces
}
export -f configure

install microk8s
