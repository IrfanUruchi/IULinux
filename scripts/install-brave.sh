#!/usr/bin/env bash
set -Eeuo pipefail

trap 'echo "[IULinux] ERROR: Brave installation failed at line ${LINENO}" >&2' ERR

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"
CHROOT_RUN="${PROJECT_ROOT}/scripts/chroot-run.sh"

KEY_URL="https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg"
SOURCE_URL="https://brave-browser-apt-release.s3.brave.com/brave-browser.sources"

[[ -d "${ROOTFS_DIR}" ]] || {
    echo "[IULinux] Rootfs missing." >&2
    exit 1
}

sudo -v

echo "============================================"
echo " IULinux Brave Browser installation"
echo "============================================"

echo
echo "[IULinux] Installing Brave repository key..."

curl -fsSL "${KEY_URL}" |
    sudo tee \
        "${ROOTFS_DIR}/usr/share/keyrings/brave-browser-archive-keyring.gpg" \
        >/dev/null

sudo chmod 0644 \
    "${ROOTFS_DIR}/usr/share/keyrings/brave-browser-archive-keyring.gpg"

echo "[IULinux] Installing Brave repository definition..."

curl -fsSL "${SOURCE_URL}" |
    sudo tee \
        "${ROOTFS_DIR}/etc/apt/sources.list.d/brave-browser-release.sources" \
        >/dev/null

sudo chmod 0644 \
    "${ROOTFS_DIR}/etc/apt/sources.list.d/brave-browser-release.sources"

echo
echo "[IULinux] Updating package metadata..."

"${CHROOT_RUN}" apt-get update

echo
echo "[IULinux] Installing Brave..."

"${CHROOT_RUN}" \
    /usr/bin/env \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install \
        -y \
        --no-install-recommends \
        brave-browser

echo
echo "[IULinux] Cleaning package cache..."

"${CHROOT_RUN}" apt-get clean

echo
echo "[IULinux] Re-applying IULinux overlay..."

"${PROJECT_ROOT}/scripts/apply-overlay.sh"

echo
echo "============================================"
echo " Brave Browser installation COMPLETE"
echo "============================================"

"${CHROOT_RUN}" dpkg-query -W brave-browser
