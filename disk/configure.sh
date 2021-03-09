#!/bin/bash -e
set -o pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"

ask(){
    read -r -p "${1}: " ANSWER
}

generate(){
    CONFIG="${SCRIPT_DIR}/user-data.secret"
    [[ -e "${CONFIG}" ]] && rm "${CONFIG}"
    touch "${CONFIG}"
    chmod 600 "$CONFIG"
    for VAR in host.name default_user; do
        ask "$VAR"
        echo "${VAR}: ${ANSWER}" >> "${CONFIG}"
    done
    echo "default_user.ssh.authorized_keys: $(cat "$HOME/.ssh/id_rsa.pub" | cut -d" " -f1,2)" >> $CONFIG
}

generate
echo
echo "[OK]"
