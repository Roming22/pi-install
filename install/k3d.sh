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

    # Create default admin-user
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
EOF
    cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF

    # Generate a token
    kubectl -n kubernetes-dashboard describe secret $(\
        kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}' \
    ) | grep -E "^token:" | sed "s/^token: *//" > ~/.kube/admin-user.token

    # Display the current state
    kubectl get all --all-namespaces
}
export -f configure

install k3d
