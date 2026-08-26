#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"

[[ -d "${ROOTFS_DIR}" ]] || {
    echo "[IULinux] Rootfs missing: ${ROOTFS_DIR}" >&2
    exit 1
}

(($# > 0)) || {
    echo "Usage: $0 <command> [args...]" >&2
    exit 2
}

sudo -v

cleanup()
{
    rc=$?

    trap - EXIT INT TERM HUP
    set +e

    for mp in \
        "${ROOTFS_DIR}/run" \
        "${ROOTFS_DIR}/sys" \
        "${ROOTFS_DIR}/proc" \
        "${ROOTFS_DIR}/dev/pts" \
        "${ROOTFS_DIR}/dev"
    do
        if mountpoint -q "${mp}"; then
            sudo umount -R "${mp}" 2>/dev/null ||
                sudo umount -l "${mp}" 2>/dev/null ||
                true
        fi
    done

    exit "${rc}"
}

trap cleanup EXIT INT TERM HUP

sudo mkdir -p \
    "${ROOTFS_DIR}/dev" \
    "${ROOTFS_DIR}/proc" \
    "${ROOTFS_DIR}/sys" \
    "${ROOTFS_DIR}/run"

sudo mount --rbind /dev "${ROOTFS_DIR}/dev"
sudo mount --make-rslave "${ROOTFS_DIR}/dev"

sudo mount -t proc proc "${ROOTFS_DIR}/proc"

sudo mount --rbind /sys "${ROOTFS_DIR}/sys"
sudo mount --make-rslave "${ROOTFS_DIR}/sys"

sudo mount --rbind /run "${ROOTFS_DIR}/run"
sudo mount --make-rslave "${ROOTFS_DIR}/run"

sudo chroot "${ROOTFS_DIR}" \
    /usr/bin/env \
    HOME=/root \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    "$@"
