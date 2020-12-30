#!/bin/bash -e
set -o pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"

ask(){
    read -r -p "${1}: " ANSWER
}

generate(){
    while true; do
        ask "Cluster name"
        case $ANSWER in
            "") ;;
            *) CLUSTER_NAME="$ANSWER"; break ;;
        esac
    done
    ANSIBLE_DIR="${SCRIPT_DIR}/k3s-ansible/inventory/${CLUSTER_NAME}"
    rsync --archive "${SCRIPT_DIR}/k3s-ansible/inventory/sample/" "${ANSIBLE_DIR}"

    #
    # vars.yaml
    #
    ALL_YML="${ANSIBLE_DIR}/group_vars/all.yml"
    VAR="ansible_user"
    ask "Default user [$(grep -E "^$VAR:" "${ALL_YML}" | cut -d" " -f2)]"
    case $ANSWER in
        "") ;;
        *) sed -i -e "s/^$VAR:.*/$VAR: $ANSWER/" "${ALL_YML}" ;;
    esac
    VAR="k3s_version"
    ask "k3s version [$(grep -E "^$VAR:" "${ALL_YML}" | cut -d" " -f2)]"
    case $ANSWER in
        "") ;;
        *) sed -i -e "s/^$VAR:.*/$VAR: $ANSWER/" "${ALL_YML}" ;;
    esac


    #
    # hosts.ini
    #
    HOSTS_INI="${ANSIBLE_DIR}/hosts.ini"

    echo "Enter master nodes' IPs (leave blank to stop)"
    echo "[master]" > "${HOSTS_INI}"
    while true; do
        ask "  - Master node ip"
        case $ANSWER in
            "") echo >> "${HOSTS_INI}"; break ;;
            *) echo "${ANSWER}" >> "${HOSTS_INI}" ;;
        esac
    done

    echo "Enter worker nodes' IPs (leave blank to stop)"
    echo "[node]" >> "${HOSTS_INI}"
    while true; do
        ask "  - Worker node ip"
        case $ANSWER in
            "") echo >> "${HOSTS_INI}"; break ;;
            *) echo "${ANSWER}" >> "${HOSTS_INI}";;
        esac
    done

   echo "[k3s_cluster:children]
master
node" >> "${HOSTS_INI}" 
}

generate
echo
echo "[OK]"
