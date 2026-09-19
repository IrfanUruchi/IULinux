#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"

fail()
{
    echo "[FAIL] $*" >&2
    exit 1
}

package_status()
{
    dpkg-query \
        --admindir="${ROOTFS_DIR}/var/lib/dpkg" \
        -W \
        -f='${db:Status-Abbrev}' \
        "$1" 2>/dev/null || true
}

[[ -d "${ROOTFS_DIR}" ]] ||
    fail "Rootfs missing"

required_packages=(
    plasma-desktop
    plasma-workspace
    plasma-session-wayland
    kwin-wayland
    sddm
    dolphin
    gnome-terminal
    resources
    btop
    systemd-timesyncd
    plasma-nm
    plasma-pa
    pipewire
    wireplumber
    xwayland
)

for package in "${required_packages[@]}"; do
    [[ "$(package_status "${package}")" == "ii " ]] ||
        fail "Desktop package missing: ${package}"
done

for package in \
    konsole \
    konsole-kpart \
    plasma-systemmonitor \
    gnome-system-monitor
do
    [[ "$(package_status "${package}")" != "ii " ]] ||
        fail "Superseded desktop package installed: ${package}"
done

[[ -x "${ROOTFS_DIR}/usr/bin/startplasma-wayland" ]] ||
    fail "startplasma-wayland missing"

[[ -x "${ROOTFS_DIR}/usr/bin/kwin_wayland" ]] ||
    fail "kwin_wayland missing"

[[ -x "${ROOTFS_DIR}/usr/bin/dolphin" ]] ||
    fail "Dolphin missing"

[[ -x "${ROOTFS_DIR}/usr/bin/gnome-terminal" ]] ||
    fail "GNOME Terminal missing"

[[ -x "${ROOTFS_DIR}/usr/bin/resources" ]] ||
    fail "Resources missing"

[[ -x "${ROOTFS_DIR}/usr/bin/iulinux-settings" ]] ||
    fail "IULinux Settings missing"

[[ -x "${ROOTFS_DIR}/usr/lib/iulinux/iulinux-performance-status" ]] ||
    fail "IULinux performance telemetry missing"

[[ -f "${ROOTFS_DIR}/usr/share/applications/com.iulinux.Settings.desktop" ]] ||
    fail "IULinux Settings desktop entry missing"

[[ -f "${ROOTFS_DIR}/usr/share/plasma/plasmoids/com.iulinux.performance/metadata.json" ]] ||
    fail "IULinux performance plasmoid metadata missing"

[[ -f "${ROOTFS_DIR}/usr/share/plasma/plasmoids/com.iulinux.performance/contents/ui/main.qml" ]] ||
    fail "IULinux performance plasmoid UI missing"

terminal="$(
    readlink \
        "${ROOTFS_DIR}/etc/alternatives/x-terminal-emulator" \
        2>/dev/null || true
)"

[[ "${terminal}" == "/usr/bin/gnome-terminal.wrapper" ]] ||
    fail "GNOME Terminal is not the default terminal"

[[ -e "${ROOTFS_DIR}/etc/systemd/system/default.target" ]] ||
    fail "default systemd target missing"

default_target="$(
    readlink "${ROOTFS_DIR}/etc/systemd/system/default.target" || true
)"

[[ "${default_target}" == "/usr/lib/systemd/system/graphical.target" ]] ||
    fail "Default target is not graphical.target"

grep -qx 'ID=iulinux' \
    "${ROOTFS_DIR}/usr/lib/os-release" ||
    fail "IULinux identity missing"

echo "[PASS] IULinux KDE Plasma desktop"
