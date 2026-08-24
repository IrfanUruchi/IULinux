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

OS_RELEASE="${ROOTFS_DIR}/usr/lib/os-release"
IULINUX_ICON="${ROOTFS_DIR}/usr/share/icons/hicolor/512x512/apps/iulinux.png"

grep -qx 'LOGO=iulinux' "${OS_RELEASE}" ||
    fail "IULinux os-release logo identity missing"

grep -qx 'VARIANT="Development"' "${OS_RELEASE}" ||
    fail "IULinux development variant missing"

grep -qx 'VARIANT_ID=development' "${OS_RELEASE}" ||
    fail "IULinux development variant ID missing"

grep -qx 'ANSI_COLOR="0;94"' "${OS_RELEASE}" ||
    fail "IULinux terminal identity color missing"

[[ -f "${IULINUX_ICON}" ]] ||
    fail "IULinux distribution icon missing"

[[ -s "${IULINUX_ICON}" ]] ||
    fail "IULinux distribution icon is empty"

echo "[PASS] IULinux rootfs identity"
