#!/bin/bash -e
reset
date
ansible-playbook -v -i hosts.yml sites.yml
scp pi@192.168.72.90:.kube/config /home/rarnaud/.kube/config
cat ~/.kube/config
kubectl get nodes
curl -k -s https://192.168.72.90/
date
