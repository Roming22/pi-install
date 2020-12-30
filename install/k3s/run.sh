#!/bin/bash -e
set -o pipefail
SCRIPT_DIR="$(dirname $(realpath "$0"))"

ask(){
    read -r -p "${1}: " ANSWER
}

run(){
    ANSIBLE_DIR="${SCRIPT_DIR}/k3s-ansible"
    for CLUSTER in $(ls ${ANSIBLE_DIR}/inventory/ | grep -E -v "^sample$"); do
        echo; echo "[$CLUSTER]"
        HOSTS_INI="${ANSIBLE_DIR}/inventory/${CLUSTER}/hosts.ini"
        ansible-playbook "${ANSIBLE_DIR}/site.yml" -i "${HOSTS_INI}"
        echo "[$CLUSTER: OK]"; echo
    done
}

run
echo
echo "[OK]"
