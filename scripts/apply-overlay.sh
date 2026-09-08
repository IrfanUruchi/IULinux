#!/usr/bin/env bash
set -Eeuo pipefail

trap 'echo "[IULinux] ERROR: overlay application failed at line ${LINENO}" >&2' ERR

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"
OVERLAY_DIR="${PROJECT_ROOT}/overlay"
PROFILES_DIR="${PROJECT_ROOT}/profiles"

if [[ ! -d "${ROOTFS_DIR}" ]]; then
    echo "[IULinux] Rootfs does not exist: ${ROOTFS_DIR}" >&2
    echo "[IULinux] Run ./scripts/bootstrap-rootfs.sh first." >&2
    exit 1
fi

if [[ ! -d "${OVERLAY_DIR}" ]]; then
    echo "[IULinux] Overlay directory missing: ${OVERLAY_DIR}" >&2
    exit 1
fi

sudo -v

echo "============================================"
echo " IULinux overlay"
echo "============================================"
echo "Source: ${OVERLAY_DIR}"
echo "Target: ${ROOTFS_DIR}"
echo

# Preserve upstream Ubuntu identity for debugging and provenance.
sudo mkdir -p "${ROOTFS_DIR}/usr/lib/iulinux"

if [[ -f "${ROOTFS_DIR}/usr/lib/os-release" ]] &&
   [[ ! -f "${ROOTFS_DIR}/usr/lib/iulinux/upstream-os-release" ]]; then
    sudo cp \
        "${ROOTFS_DIR}/usr/lib/os-release" \
        "${ROOTFS_DIR}/usr/lib/iulinux/upstream-os-release"
fi

echo "[IULinux] Applying filesystem overlay..."

sudo rsync \
    -aH \
    --exclude='.gitkeep' \
    --chown=root:root \
    "${OVERLAY_DIR}/" \
    "${ROOTFS_DIR}/"


echo "[IULinux] Staging optional profiles..."

sudo mkdir -p "${ROOTFS_DIR}/usr/share/iulinux/profiles"

sudo rsync \
    -aH \
    --delete \
    --exclude='.gitkeep' \
    --chown=root:root \
    "${PROFILES_DIR}/" \
    "${ROOTFS_DIR}/usr/share/iulinux/profiles/"

# Netplan configuration must not be world-readable.
if [[ -d "${ROOTFS_DIR}/etc/netplan" ]]; then
    sudo find "${ROOTFS_DIR}/etc/netplan" \
        -type f \
        \( -name '*.yaml' -o -name '*.yml' \) \
        -exec chmod 0600 {} +
fi

# Ubuntu normally exposes /etc/os-release through /usr/lib/os-release.
# Re-establish that relationship explicitly.
sudo rm -f "${ROOTFS_DIR}/etc/os-release"
sudo ln -s ../usr/lib/os-release "${ROOTFS_DIR}/etc/os-release"

echo
echo "[IULinux] Overlay applied successfully."
