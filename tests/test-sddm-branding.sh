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

WALLPAPER="${ROOTFS_DIR}/usr/share/wallpapers/IULinux/contents/images/3840x2160.png"

FACE_DIR="${ROOTFS_DIR}/usr/share/sddm/faces"
LIVE_FACE="${FACE_DIR}/iulinux.face.icon"

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

grep -qx 'Current=iulinux' "${SDDM_POLICY}" ||
    fail "IULinux SDDM theme is not IULinux"

# ------------------------------------------------------------
# IULinux SDDM theme
# ------------------------------------------------------------

IULINUX_THEME="${ROOTFS_DIR}/usr/share/sddm/themes/iulinux"

[[ -s "${IULINUX_THEME}/Main.qml" ]] ||
    fail "IULinux SDDM Main.qml missing or empty"

[[ -s "${IULINUX_THEME}/Login.qml" ]] ||
    fail "IULinux SDDM Login.qml missing or empty"

[[ -s "${IULINUX_THEME}/metadata.desktop" ]] ||
    fail "IULinux SDDM metadata missing or empty"

[[ -s "${IULINUX_THEME}/theme.conf" ]] ||
    fail "IULinux SDDM theme.conf missing or empty"

grep -qx 'Theme-Id=iulinux' "${IULINUX_THEME}/metadata.desktop" ||
    fail "IULinux SDDM theme ID incorrect"

grep -qx 'showlogo=shown' "${IULINUX_THEME}/theme.conf" ||
    fail "IULinux SDDM logo policy missing"

grep -qx 'logo=/usr/share/pixmaps/iulinux-logo.png' "${IULINUX_THEME}/theme.conf" ||
    fail "IULinux SDDM logo path incorrect"

grep -qx     'background=/usr/share/wallpapers/IULinux/contents/images/3840x2160.png'     "${IULINUX_THEME}/theme.conf" ||
    fail "IULinux SDDM wallpaper policy incorrect"

grep -qx 'color=#0b0f14' "${IULINUX_THEME}/theme.conf" ||
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

# ------------------------------------------------------------
# IULinux live-user avatar
# ------------------------------------------------------------

grep -qx 'FacesDir=/usr/share/sddm/faces' "${SDDM_POLICY}" ||
    fail "IULinux SDDM FacesDir policy missing"

grep -qx 'EnableAvatars=true' "${SDDM_POLICY}" ||
    fail "IULinux SDDM avatar policy missing"

[[ -f "${LIVE_FACE}" ]] ||
    fail "IULinux live-user SDDM avatar missing"

[[ -s "${LIVE_FACE}" ]] ||
    fail "IULinux live-user SDDM avatar is empty"

echo "[PASS] IULinux SDDM branding"
