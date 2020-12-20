#!/bin/bash -e
set -o pipefail
#set -x
UBUNTU_VERSION="20.10"
TMP_DIR="$(cd "$(dirname "$0")"; pwd)/tmp"

now(){
	date +%H:%M:%S
}

# Making sure the script is run as root
if [[ "$UID" != "0" ]]; then
	echo "Run with sudo" >&2
	exit 1
fi

echo "$(now) Looking for device..."
list_disks(){
	lsblk -l -o NAME,TYPE | grep -E "\sdisk$" | cut -d" " -f1
}
# Wait for the disk to be inserted
DISK_COUNT="$(list_disks | wc -l)"
DISK_LIST="$(list_disks | sed "s:.*:^\0$:" | tr "\n" "|")"
DISK_LIST="${DISK_LIST%?}"
echo "Insert the device to continue"
while [[ $(list_disks | wc -l) -eq "${DISK_COUNT}" ]]; do
	sleep 1
done
DISK="/dev/$(list_disks | grep -v $DISK_LIST)"

# Check that the boot disk was not found by mistakea
if [[ $(df | grep "${DISK}" | grep -c "/boot") != "0" ]]; then
	echo "Something unexpected happened. Try again." >&2
	exit 1
fi

# Warn user before wiping the disk
echo "All data on $DISK is going to be lost."
while true; do
	read -r -p "Do you want to continue? [y|N]: " ANSWER
	case "${ANSWER}" in
		y|Y) break ;;
		n|N|"") echo "[Interrupted]"; exit 0;;
	esac
done

mkdir -p "$TMP_DIR"

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
IMAGE="${TMP_DIR}/ubuntu-${UBUNTU_VERSION}-${TYPE}.img.xz"
[[ -e "${IMAGE}" ]] || curl -o "${IMAGE}" "https://cdimage.ubuntu.com/releases/${UBUNTU_VERSION}/release/ubuntu-${UBUNTU_VERSION}-preinstalled-${TYPE}-arm64+raspi.img.xz"

echo "$(now) Unmounting all partitions..."
df | grep -E "^${DISK}p?[0-9]+\s" | cut -d" " -f1 | xargs --no-run-if-empty umount -f || true

echo "$(now) Copying image to device..."
xzcat "$IMAGE" | dd bs=4M of="${DISK}" status=progress

echo "$(now) Remounting filesystems..."
partprobe "${DISK}"
for PART in system-boot, writeable; do
	PART_NUM="$(( PART_NUM+1 ))"
	mkdir -p "${TMP_DIR}/${PART}
	"$(ls "${DISK}${PART_NUM}" || mount "${DISK}p${PART_NUM}")" "${TMP_DIR}/${PART}
done

# echo "$(now) Configuring first boot process..."

echo "$(now) Unmounting filesystems..."
df | grep -E "^${DISK}p?[0-9]+\s" | cut -d" " -f1 | xargs --no-run-if-empty umount -f || true

# Clean up
rm -rf "${TMP_DIR}"

echo "$(now) The device is ejected and can be safely removed."
echo
echo "[OK]"
