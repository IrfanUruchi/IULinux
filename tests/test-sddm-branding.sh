#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"

fail()
{
    echo "[FAIL] $*" >&2
    exit 1
}

SDDM_POLICY="${ROOTFS_DIR}/etc/sddm.conf.d/20-iulinux-theme.conf"
BREEZE_THEME="${ROOTFS_DIR}/usr/share/sddm/themes/breeze"
THEME_OVERRIDE="${BREEZE_THEME}/theme.conf.user"

WALLPAPER="${ROOTFS_DIR}/usr/share/wallpapers/IULinux/contents/images/1672x941.png"

LIVE_CONFIG="${ROOTFS_DIR}/etc/sddm.conf.d/iulinux-live.conf"

status="$(
    dpkg-query \
        --admindir="${ROOTFS_DIR}/var/lib/dpkg" \
        -W \
        -f='${db:Status-Abbrev}' \
        sddm 2>/dev/null || true
)"

[[ "${status}" == "ii " ]] ||
    fail "SDDM is not installed"

[[ -d "${BREEZE_THEME}" ]] ||
    fail "Breeze SDDM theme missing"

[[ -f "${SDDM_POLICY}" ]] ||
    fail "IULinux SDDM theme policy missing"

grep -qx 'Current=breeze' "${SDDM_POLICY}" ||
    fail "IULinux SDDM theme is not Breeze"

[[ -f "${THEME_OVERRIDE}" ]] ||
    fail "IULinux SDDM Breeze override missing"

grep -qx 'type=image' "${THEME_OVERRIDE}" ||
    fail "IULinux SDDM image mode missing"

grep -qx \
    'background=/usr/share/wallpapers/IULinux/contents/images/1672x941.png' \
    "${THEME_OVERRIDE}" ||
    fail "IULinux SDDM wallpaper policy incorrect"

grep -qx 'color=#0b0f16' "${THEME_OVERRIDE}" ||
    fail "IULinux SDDM fallback color incorrect"

[[ -f "${WALLPAPER}" ]] ||
    fail "IULinux SDDM wallpaper asset missing"

[[ -s "${WALLPAPER}" ]] ||
    fail "IULinux SDDM wallpaper asset empty"

# Preserve the existing live-session autologin policy.
[[ -f "${LIVE_CONFIG}" ]] ||
    fail "IULinux live SDDM configuration missing"

grep -qx 'User=iulinux' "${LIVE_CONFIG}" ||
    fail "IULinux live autologin user changed"

grep -qx 'Session=plasma.desktop' "${LIVE_CONFIG}" ||
    fail "IULinux live Plasma session changed"

echo "[PASS] IULinux SDDM branding"
