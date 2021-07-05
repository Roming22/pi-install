#!/bin/bash -e
SCRIPT_DIR="$(dirname "$(realpath $0)")"
ANSIBLE_DIR="${SCRIPT_DIR}/ansible"
TARGET="192.168.72.90"
reset
date
ansible-playbook -v -i "${ANSIBLE_DIR}/hosts.yml" "${ANSIBLE_DIR}/sites.yml"
scp "${TARGET}:.kube/config" /home/rarnaud/.kube/config
cat ~/.kube/config
kubectl get nodes
date
