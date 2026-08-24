#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 COMMAND [ARGUMENTS...]" >&2
    exit 2
fi

if [[ ! -d "${ROOTFS_DIR}" ]]; then
    echo "[IULinux] Missing rootfs: ${ROOTFS_DIR}" >&2
    exit 1
fi

sudo -v

MOUNTS=()
RESOLV_BACKUP="$(mktemp -d)"
HAD_RESOLV=0

cleanup()
{
    set +e

    for ((i=${#MOUNTS[@]}-1; i>=0; i--)); do
        sudo umount "${MOUNTS[$i]}" 2>/dev/null || true
    done

    if [[ "${HAD_RESOLV}" -eq 1 ]]; then
        sudo rm -f "${ROOTFS_DIR}/etc/resolv.conf"
        sudo cp -a "${RESOLV_BACKUP}/resolv.conf" \
            "${ROOTFS_DIR}/etc/resolv.conf"
    else
        sudo rm -f "${ROOTFS_DIR}/etc/resolv.conf"
    fi

    rm -rf "${RESOLV_BACKUP}"
}

trap cleanup EXIT
trap 'echo "[IULinux] ERROR: chroot command failed at line ${LINENO}" >&2' ERR

mount_bind()
{
    local source="$1"
    local target="$2"

    sudo mkdir -p "${target}"

    if ! mountpoint -q "${target}"; then
        sudo mount --bind "${source}" "${target}"
        MOUNTS+=("${target}")
    fi
}

mount_fs()
{
    local type="$1"
    local source="$2"
    local target="$3"

    sudo mkdir -p "${target}"

    if ! mountpoint -q "${target}"; then
        sudo mount -t "${type}" "${source}" "${target}"
        MOUNTS+=("${target}")
    fi
}

if [[ -e "${ROOTFS_DIR}/etc/resolv.conf" ||
      -L "${ROOTFS_DIR}/etc/resolv.conf" ]]; then
    sudo cp -a "${ROOTFS_DIR}/etc/resolv.conf" \
        "${RESOLV_BACKUP}/resolv.conf"
    HAD_RESOLV=1
fi

sudo rm -f "${ROOTFS_DIR}/etc/resolv.conf"
sudo cp -L /etc/resolv.conf "${ROOTFS_DIR}/etc/resolv.conf"

mount_bind /dev "${ROOTFS_DIR}/dev"
mount_bind /dev/pts "${ROOTFS_DIR}/dev/pts"
mount_fs proc proc "${ROOTFS_DIR}/proc"
mount_fs sysfs sys "${ROOTFS_DIR}/sys"

sudo chroot "${ROOTFS_DIR}" \
    /usr/bin/env \
    HOME=/root \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    "$@"
