#!/bin/bash -e
set -o pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")"; pwd)"
#set -x
DISK="$1"
UBUNTU_VERSION="20.10"
TMP_DIR="${SCRIPT_DIR}/tmp"

now(){
    date +%H:%M:%S
}

# Making sure the script is run as root
if [[ "$UID" != "0" ]]; then
    echo "Run with sudo" >&2
    exit 1
fi

list_disks(){
    lsblk -l -o NAME,TYPE | grep -E "\sdisk$" | cut -d" " -f1
}

wait_for_disk(){
    # Wait for the disk to be inserted
    echo "$(now) Looking for device..."
    DISK_COUNT="$(list_disks | wc -l)"
    DISK_LIST="$(list_disks | sed "s:.*:^\0$:" | tr "\n" "|")"
    DISK_LIST="${DISK_LIST%?}"
    echo "Insert the device to continue"
    while [[ $(list_disks | wc -l) -eq "${DISK_COUNT}" ]]; do
        sleep 1
    done
    DISK="/dev/$(list_disks | grep -E -v $DISK_LIST)"
}

get_disk(){
    if [[ -n "${DISK}" ]]; then
        if [[ ! -e "${DISK}" ]]; then
            echo "${DISK} not found" >&2
            exit 1
        fi
    else
        wait_for_disk
    fi

    # Check that the boot disk was not found by mistakea
    if [[ $(df | grep "${DISK}" | grep -c "/boot") != "0" ]]; then
        echo "Something unexpected happened. Try again." >&2
        exit 1
    fi
}

download_image(){
    mkdir -p "${SCRIPT_DIR}/images"

    echo "$(now) Downloading image..."
    unset TYPE
    echo "Which image do you want to download:"
    echo "  1- Desktop"
    echo "  2- Server"
    while true; do
        read -r -p "Select image: " ANSWER
        case "${ANSWER}" in
            1) TYPE="desktop" ;;
            2) TYPE="server" ;;
        esac
        [[ -z "$TYPE" ]] || break
    done
    IMAGE="${SCRIPT_DIR}/images/ubuntu-${UBUNTU_VERSION}-${TYPE}.img.xz"
    [[ -e "${IMAGE}" ]] || curl -o "${IMAGE}" "https://cdimage.ubuntu.com/releases/${UBUNTU_VERSION}/release/ubuntu-${UBUNTU_VERSION}-preinstalled-${TYPE}-arm64+raspi.img.xz"
}

unmount_partitions(){
    df | grep -E "^${DISK}p?[0-9]+\s" | cut -d" " -f1 | while read PARTITION; do
        umount -l $PARTITION
        umount -f $PARTITION || true
    done
    
}

copy_image(){
    unmount_partitions
    echo "$(now) Copying image to device..."

    # Warn user before wiping the disk
    echo "All data on $DISK is going to be lost."
    while true; do
        read -r -p "Do you want to continue? [y|N]: " ANSWER
        case "${ANSWER}" in
            y|Y) break ;;
            n|N|"") echo "[Interrupted]"; exit 0;;
        esac
    done

    # Write image to disk
    xzcat "$IMAGE" | dd bs=4M of="${DISK}" status=progress

    # Refresh disk info
    partprobe "${DISK}"
}

mount_partitions(){
    mkdir -p "${TMP_DIR}"
    for PART in system-boot writeable; do
        PART_NUM="$(( PART_NUM+1 ))"
        mkdir -p "${TMP_DIR}/${PART}"
        mount "$(ls "${DISK}${PART_NUM}" || ls "${DISK}p${PART_NUM}")" "${TMP_DIR}/${PART}"
    done
}

configure_first_boot(){
    echo "$(now) Configuring first boot process..."
    mount_partitions

    # Generate cloud-init user-data file
    [[ ! -e "${TMP_DIR}/system-boot/user-data" ]] || mv "${TMP_DIR}/system-boot/user-data" "${TMP_DIR}/system-boot/user-data.bak"
    cp "${SCRIPT_DIR}/user-data" "${TMP_DIR}/system-boot"
    IFS_OLD="${IFS}"
    IFS=$'\n'
    for VAR in $(grep -E "%.*%" user-data | cut -d% -f2); do
        VALUE=$(grep -E "^${VAR}:" "${SCRIPT_DIR}/user-data.secret" | cut -d: -f2- | sed -e "s:^ *::")
        sed -i -e "s:%${VAR}%:${VALUE}:" "${TMP_DIR}/system-boot/user-data"
    done
    IFS="${IFS_OLD}"

    # Prepare system for docker/k8s
    sed -i -e "s:rootwait:cgroup_memory=1 cgroup_enable=memory \0:" ${TMP_DIR}/system-boot/cmdline.txt

    sync
    unmount_partitions
}


cleanup(){
    rm -rf "${TMP_DIR}"
}

get_disk
download_image
copy_image
configure_first_boot
cleanup
echo "$(now) The device is ejected and can be safely removed."
echo
echo "[OK]"
