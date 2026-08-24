#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"

fail()
{
    echo "[FAIL] $*" >&2
    exit 1
}

[[ -d "${ROOTFS_DIR}" ]] ||
    fail "Rootfs missing"

required_packages=(
    linux-generic
    linux-firmware
    initramfs-tools
    systemd-sysv
    network-manager
)

for package in "${required_packages[@]}"; do
    dpkg-query \
        --admindir="${ROOTFS_DIR}/var/lib/dpkg" \
        -W \
        -f='${db:Status-Abbrev}' \
        "${package}" 2>/dev/null |
        grep -qx 'ii ' ||
        fail "Required package not installed: ${package}"
done

[[ -x "${ROOTFS_DIR}/usr/bin/systemctl" ]] ||
    fail "systemctl missing"

[[ -x "${ROOTFS_DIR}/usr/bin/nmcli" ]] ||
    fail "nmcli missing"

kernel_count="$(
    find "${ROOTFS_DIR}/boot" \
        -maxdepth 1 \
        -type f \
        -name 'vmlinuz-*' |
        wc -l
)"

initrd_count="$(
    find "${ROOTFS_DIR}/boot" \
        -maxdepth 1 \
        -type f \
        -name 'initrd.img-*' |
        wc -l
)"

[[ "${kernel_count}" -ge 1 ]] ||
    fail "No kernel image found"

[[ "${initrd_count}" -ge 1 ]] ||
    fail "No initramfs found"

grep -qx 'ID=iulinux' \
    "${ROOTFS_DIR}/usr/lib/os-release" ||
    fail "IULinux identity missing"

echo "[PASS] IULinux base system"
