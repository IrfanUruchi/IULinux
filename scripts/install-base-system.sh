#!/usr/bin/env bash
set -Eeuo pipefail

trap 'echo "[IULinux] ERROR: base-system installation failed at line ${LINENO}" >&2' ERR

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"
PACKAGE_LIST="${PROJECT_ROOT}/packages/base.list"
CHROOT_RUN="${PROJECT_ROOT}/scripts/chroot-run.sh"

if [[ ! -d "${ROOTFS_DIR}" ]]; then
    echo "[IULinux] Missing rootfs." >&2
    echo "[IULinux] Run ./scripts/bootstrap-rootfs.sh first." >&2
    exit 1
fi

if [[ ! -f "${PACKAGE_LIST}" ]]; then
    echo "[IULinux] Missing package manifest: ${PACKAGE_LIST}" >&2
    exit 1
fi

mapfile -t PACKAGES < <(
    sed \
        -e 's/[[:space:]]*#.*$//' \
        -e '/^[[:space:]]*$/d' \
        "${PACKAGE_LIST}"
)

if [[ "${#PACKAGES[@]}" -eq 0 ]]; then
    echo "[IULinux] Base package manifest is empty." >&2
    exit 1
fi

sudo -v

echo "============================================"
echo " IULinux base system installation"
echo "============================================"
echo "Packages: ${#PACKAGES[@]}"
echo

# Prevent package post-install scripts from trying to start services
# while constructing the offline image.
sudo tee "${ROOTFS_DIR}/usr/sbin/policy-rc.d" >/dev/null <<'POLICY'
#!/bin/sh
exit 101
POLICY

sudo chmod 755 "${ROOTFS_DIR}/usr/sbin/policy-rc.d"

cleanup()
{
    sudo rm -f "${ROOTFS_DIR}/usr/sbin/policy-rc.d"
}

trap cleanup EXIT

echo "[IULinux] Updating package indexes..."

"${CHROOT_RUN}" \
    /usr/bin/env \
    DEBIAN_FRONTEND=noninteractive \
    apt-get update

echo
echo "[IULinux] Installing base packages..."

"${CHROOT_RUN}" \
    /usr/bin/env \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install \
        -y \
        --no-install-recommends \
        "${PACKAGES[@]}"

echo
echo "[IULinux] Cleaning package cache..."

"${CHROOT_RUN}" \
    apt-get clean

cleanup
trap - EXIT

echo "============================================"
echo " IULinux base system COMPLETE"
echo "============================================"

echo
echo "Installed kernels:"
find "${ROOTFS_DIR}/boot" \
    -maxdepth 1 \
    \( -name 'vmlinuz-*' -o -name 'initrd.img-*' \) \
    -printf '%f\n' \
    2>/dev/null | sort

echo
echo "Rootfs size:"
sudo du -sh "${ROOTFS_DIR}"
