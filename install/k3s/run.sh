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
        ALL_YML="${ANSIBLE_DIR}/inventory/${CLUSTER}/group_vars/all.yml"
        HOSTS_INI="${ANSIBLE_DIR}/inventory/${CLUSTER}/hosts.ini"
        ansible-playbook "${ANSIBLE_DIR}/site.yml" -i "${HOSTS_INI}"
        DEFAULT_USER="$(grep -E "^ansible_user:" "${ALL_YML}" | sed -e "s/.*: //")"
        MASTER0_IP="$(ansible-inventory --list -i "${HOSTS_INI}" | grep -A2 master | tail -1 | cut -d'"' -f2)"
        scp "${DEFAULT_USER}@${MASTER0_IP}:~/.kube/config" "$HOME/.kube/config.${CLUSTER}"
        echo "[$CLUSTER: OK]"; echo
    done
}

run
echo
echo "[OK]"
