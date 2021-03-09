#!/bin/bash -e
SCRIPT_DIR="$(dirname "$(realpath $0)")"
ANSIBLE_DIR="${SCRIPT_DIR}/ansible"
reset
date
ansible-playbook -v -i "${ANSIBLE_DIR}/hosts.yml" "${ANSIBLE_DIR}/sites.yml"
scp pi@192.168.72.90:.kube/config /home/rarnaud/.kube/config
cat ~/.kube/config
kubectl get nodes
curl -k -s https://192.168.72.90/
date
