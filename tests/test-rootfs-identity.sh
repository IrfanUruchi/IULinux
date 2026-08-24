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

[[ -f "${ROOTFS_DIR}/usr/lib/os-release" ]] ||
    fail "/usr/lib/os-release missing"

grep -qx 'ID=iulinux' \
    "${ROOTFS_DIR}/usr/lib/os-release" ||
    fail "IULinux ID missing"

grep -qx 'ID_LIKE="ubuntu debian"' \
    "${ROOTFS_DIR}/usr/lib/os-release" ||
    fail "Ubuntu/Debian ancestry missing"

grep -qx 'UBUNTU_CODENAME=resolute' \
    "${ROOTFS_DIR}/usr/lib/os-release" ||
    fail "Ubuntu base codename missing"

grep -qx 'UBUNTU_VERSION_ID="26.04"' \
    "${ROOTFS_DIR}/usr/lib/os-release" ||
    fail "Ubuntu base version missing"

[[ "$(cat "${ROOTFS_DIR}/etc/hostname")" == "iulinux" ]] ||
    fail "Default hostname incorrect"

[[ -f "${ROOTFS_DIR}/usr/lib/iulinux/upstream-os-release" ]] ||
    fail "Upstream Ubuntu identity was not preserved"

echo "[PASS] IULinux rootfs identity"
