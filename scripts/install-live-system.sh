#!/usr/bin/env bash
set -Eeuo pipefail

trap 'echo "[IULinux] ERROR: live-system installation failed at line ${LINENO}" >&2' ERR

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"
PACKAGE_LIST="${PROJECT_ROOT}/packages/live.list"
CHROOT_RUN="${PROJECT_ROOT}/scripts/chroot-run.sh"

[[ -d "${ROOTFS_DIR}" ]] || {
    echo "[IULinux] Missing rootfs." >&2
    exit 1
}

mapfile -t PACKAGES < <(
    sed \
        -e 's/[[:space:]]*#.*$//' \
        -e '/^[[:space:]]*$/d' \
        "${PACKAGE_LIST}"
)

[[ "${#PACKAGES[@]}" -gt 0 ]] || {
    echo "[IULinux] Live package manifest is empty." >&2
    exit 1
}

sudo -v

echo "============================================"
echo " IULinux live-system installation"
echo "============================================"

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

echo "[IULinux] Updating APT metadata..."

"${CHROOT_RUN}" \
    /usr/bin/env \
    DEBIAN_FRONTEND=noninteractive \
    apt-get update

echo
echo "[IULinux] Installing live-boot support..."

"${CHROOT_RUN}" \
    /usr/bin/env \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install \
        -y \
        --no-install-recommends \
        "${PACKAGES[@]}"

echo
echo "[IULinux] Applying live configuration..."

"${PROJECT_ROOT}/scripts/apply-overlay.sh"

KERNEL_PATH="$(
    find "${ROOTFS_DIR}/boot" \
        -maxdepth 1 \
        -type f \
        -name 'vmlinuz-*' \
        -printf '%f\n' |
        sort -V |
        tail -n1
)"

[[ -n "${KERNEL_PATH}" ]] || {
    echo "[IULinux] No kernel found." >&2
    exit 1
}

KERNEL_VERSION="${KERNEL_PATH#vmlinuz-}"

echo
echo "[IULinux] Regenerating initramfs for ${KERNEL_VERSION}..."

"${CHROOT_RUN}" \
    update-initramfs \
    -u \
    -k "${KERNEL_VERSION}"

echo
echo "[IULinux] Preparing image identity..."

# A live image should generate a machine-id at boot.
sudo truncate -s 0 "${ROOTFS_DIR}/etc/machine-id"
sudo rm -f "${ROOTFS_DIR}/var/lib/dbus/machine-id"

# Remove build-time logs.
sudo find "${ROOTFS_DIR}/var/log" \
    -type f \
    -exec truncate -s 0 {} \;

"${CHROOT_RUN}" apt-get clean

cleanup
trap - EXIT

echo
echo "============================================"
echo " IULinux live system COMPLETE"
echo "============================================"
