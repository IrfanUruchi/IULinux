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
LIVE_CONFIG="${ROOTFS_DIR}/etc/sddm.conf.d/iulinux-live.conf"

BREEZE_THEME="${ROOTFS_DIR}/usr/share/sddm/themes/breeze"
BREEZE_MAIN="${BREEZE_THEME}/Main.qml"
BREEZE_CONFIG="${BREEZE_THEME}/theme.conf"
THEME_OVERRIDE="${BREEZE_THEME}/theme.conf.user"

WALLPAPER="${ROOTFS_DIR}/usr/share/wallpapers/IULinux/contents/images/1672x941.png"

package_status()
{
    dpkg-query \
        --admindir="${ROOTFS_DIR}/var/lib/dpkg" \
        -W \
        -f='${db:Status-Abbrev}' \
        "$1" 2>/dev/null || true
}

# ------------------------------------------------------------
# SDDM package
# ------------------------------------------------------------

[[ "$(package_status sddm)" == "ii " ]] ||
    fail "SDDM is not installed"

# ------------------------------------------------------------
# Breeze SDDM theme package
# ------------------------------------------------------------

[[ "$(package_status sddm-theme-breeze)" == "ii " ]] ||
    fail "sddm-theme-breeze is not installed"

[[ -f "${BREEZE_MAIN}" ]] ||
    fail "Breeze SDDM Main.qml missing"

[[ -s "${BREEZE_MAIN}" ]] ||
    fail "Breeze SDDM Main.qml is empty"

[[ -f "${BREEZE_CONFIG}" ]] ||
    fail "Breeze SDDM theme.conf missing"

[[ -s "${BREEZE_CONFIG}" ]] ||
    fail "Breeze SDDM theme.conf is empty"

# ------------------------------------------------------------
# IULinux SDDM policy
# ------------------------------------------------------------

[[ -f "${SDDM_POLICY}" ]] ||
    fail "IULinux SDDM theme policy missing"

grep -qx '\[Theme\]' "${SDDM_POLICY}" ||
    fail "IULinux SDDM Theme section missing"

grep -qx 'Current=breeze' "${SDDM_POLICY}" ||
    fail "IULinux SDDM theme is not Breeze"

# ------------------------------------------------------------
# IULinux Breeze override
# ------------------------------------------------------------

[[ -f "${THEME_OVERRIDE}" ]] ||
    fail "IULinux SDDM Breeze override missing"

grep -qx '\[General\]' "${THEME_OVERRIDE}" ||
    fail "IULinux SDDM General section missing"

grep -qx 'type=image' "${THEME_OVERRIDE}" ||
    fail "IULinux SDDM image mode missing"

grep -qx \
    'background=/usr/share/wallpapers/IULinux/contents/images/1672x941.png' \
    "${THEME_OVERRIDE}" ||
    fail "IULinux SDDM wallpaper policy incorrect"

grep -qx 'color=#0b0f16' "${THEME_OVERRIDE}" ||
    fail "IULinux SDDM fallback color incorrect"

# ------------------------------------------------------------
# Wallpaper asset
# ------------------------------------------------------------

[[ -f "${WALLPAPER}" ]] ||
    fail "IULinux SDDM wallpaper asset missing"

[[ -s "${WALLPAPER}" ]] ||
    fail "IULinux SDDM wallpaper asset empty"

# ------------------------------------------------------------
# Preserve live-session autologin
# ------------------------------------------------------------

[[ -f "${LIVE_CONFIG}" ]] ||
    fail "IULinux live SDDM configuration missing"

grep -qx 'User=iulinux' "${LIVE_CONFIG}" ||
    fail "IULinux live autologin user changed"

grep -qx 'Session=plasma.desktop' "${LIVE_CONFIG}" ||
    fail "IULinux live Plasma session changed"

grep -qx 'Relogin=false' "${LIVE_CONFIG}" ||
    fail "IULinux live SDDM relogin policy changed"

echo "[PASS] IULinux SDDM branding"
