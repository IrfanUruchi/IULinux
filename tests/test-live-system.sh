#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"

fail()
{
    echo "[FAIL] $*" >&2
    exit 1
}

status="$(
    dpkg-query \
        --admindir="${ROOTFS_DIR}/var/lib/dpkg" \
        -W \
        -f='${db:Status-Abbrev}' \
        casper 2>/dev/null || true
)"

[[ "${status}" == "ii " ]] ||
    fail "Casper is not installed"

[[ -f "${ROOTFS_DIR}/etc/sddm.conf.d/iulinux-live.conf" ]] ||
    fail "IULinux SDDM live configuration missing"

grep -qx 'User=iulinux' \
    "${ROOTFS_DIR}/etc/sddm.conf.d/iulinux-live.conf" ||
    fail "Live autologin user incorrect"

[[ -f "${ROOTFS_DIR}/usr/share/wayland-sessions/plasma.desktop" ]] ||
    fail "Plasma Wayland session missing"

INITRD="$(
    find "${ROOTFS_DIR}/boot" \
        -maxdepth 1 \
        -type f \
        -name 'initrd.img-*' |
        sort -V |
        tail -n1
)"

[[ -n "${INITRD}" && -s "${INITRD}" ]] ||
    fail "Live initramfs missing"

if command -v lsinitramfs >/dev/null 2>&1; then
    lsinitramfs "${INITRD}" |
        grep -qE 'scripts/casper' ||
        fail "Casper scripts missing from initramfs"
fi

[[ ! -s "${ROOTFS_DIR}/etc/machine-id" ]] ||
    fail "Live machine-id should be empty"

echo "[PASS] IULinux live system"
