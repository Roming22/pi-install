#!/bin/bash -e
set -o pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"

ask(){
    read -r -p "${1}: " ANSWER
}

generate(){
    CONFIG="${SCRIPT_DIR}/user-data.secret"
    [[ -e "${CONFIG}" ]] && rm "${CONFIG}"
    for VAR in host.name default_user; do
        ask "$VAR"
        echo "${VAR}: ${ANSWER}" >> "${CONFIG}"
    done
    cat << EOF >> $CONFIG
default_user.ssh.authorized_keys: $(cat "$HOME/.ssh/id_rsa.pub" | cut -d" " -f1,2)
EOF
}

generate
echo
echo "[OK]"
