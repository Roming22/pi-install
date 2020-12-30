#!/bin/bash -e
#
# Maybe it should be done via ansible (https://docs.ansible.com/ansible/latest/collections/community/kubernetes/k8s_module.html)
#
set -o pipefail
SCRIPT_DIR="$(dirname $(realpath "$0"))"

upgrade(){
    set -x
    kubectl apply -f https://github.com/rancher/system-upgrade-controller/releases/download/v0.6.2/system-upgrade-controller.yaml
    cat << EOF | kubectl apply -f -
# Server plan
apiVersion: upgrade.cattle.io/v1
kind: Plan
metadata:
  name: server-plan
  namespace: system-upgrade
spec:
  channel: https://update.k3s.io/v1-release/channels/stable
  concurrency: 1
  cordon: true
  nodeSelector:
    matchExpressions:
    - key: node-role.kubernetes.io/master
      operator: In
      values:
      - "true"
  serviceAccountName: system-upgrade
  upgrade:
    image: rancher/k3s-upgrade
---
# Agent plan
apiVersion: upgrade.cattle.io/v1
kind: Plan
metadata:
  name: agent-plan
  namespace: system-upgrade
spec:
  channel: https://update.k3s.io/v1-release/channels/stable
  concurrency: 1
  cordon: true
  nodeSelector:
    matchExpressions:
    - key: node-role.kubernetes.io/master
      operator: DoesNotExist
  prepare:
    args:
    - prepare
    - server-plan
    image: rancher/k3s-upgrade
  serviceAccountName: system-upgrade
  upgrade:
    image: rancher/k3s-upgrade
EOF
}

upgrade
echo
echo "[OK]"
