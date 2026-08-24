#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"

fail()
{
    echo "[FAIL] $*" >&2
    exit 1
}

LAF="${ROOTFS_DIR}/usr/share/plasma/look-and-feel/com.iulinux.desktop"
BRANDING="${ROOTFS_DIR}/usr/share/iulinux/branding.conf"
KDEGLOBALS="${ROOTFS_DIR}/etc/xdg/kdeglobals"

LOGO="${ROOTFS_DIR}/usr/share/pixmaps/iulinux-logo.png"

WALLPAPER_DIR="${ROOTFS_DIR}/usr/share/wallpapers/IULinux"
WALLPAPER="${WALLPAPER_DIR}/contents/images/iulinux-default.png"
WALLPAPER_META="${WALLPAPER_DIR}/metadata.json"

[[ -f "${LAF}/metadata.json" ]] ||
    fail "IULinux Look-and-Feel metadata missing"

grep -q '"Id": "com.iulinux.desktop"' \
    "${LAF}/metadata.json" ||
    fail "IULinux Look-and-Feel ID incorrect"

[[ -f "${LAF}/contents/defaults" ]] ||
    fail "IULinux Plasma defaults missing"

grep -qx 'ColorScheme=BreezeDark' \
    "${LAF}/contents/defaults" ||
    fail "IULinux color scheme policy missing"

grep -qx 'Image=IULinux' \
    "${LAF}/contents/defaults" ||
    fail "IULinux default wallpaper policy missing"

[[ -f "${LOGO}" ]] ||
    fail "IULinux logo missing"

[[ -s "${LOGO}" ]] ||
    fail "IULinux logo is empty"

[[ -f "${WALLPAPER}" ]] ||
    fail "IULinux wallpaper missing"

[[ -s "${WALLPAPER}" ]] ||
    fail "IULinux wallpaper is empty"

[[ -f "${WALLPAPER_META}" ]] ||
    fail "IULinux wallpaper metadata missing"

grep -q '"Id": "IULinux"' \
    "${WALLPAPER_META}" ||
    fail "IULinux wallpaper package ID incorrect"

[[ -f "${BRANDING}" ]] ||
    fail "IULinux branding metadata missing"

grep -qx 'Name=IULinux' "${BRANDING}" ||
    fail "IULinux branding name missing"

[[ -f "${KDEGLOBALS}" ]] ||
    fail "IULinux KDE global defaults missing"

grep -qx 'LookAndFeelPackage=com.iulinux.desktop' \
    "${KDEGLOBALS}" ||
    fail "IULinux Look-and-Feel is not the default"

echo "[PASS] IULinux branding infrastructure"
