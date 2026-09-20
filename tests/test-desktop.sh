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
    ptyxis
    resources
    btop
    systemd-timesyncd
    plasma-nm
    plasma-pa
    pipewire
    wireplumber
    xwayland
    python3-dbus
    python3-gi
)

for package in "${required_packages[@]}"; do
    [[ "$(package_status "${package}")" == "ii " ]] ||
        fail "Desktop package missing: ${package}"
done

for package in \
    konsole \
    konsole-kpart \
    plasma-systemmonitor \
    gnome-system-monitor \
    gnome-terminal
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

[[ -x "${ROOTFS_DIR}/usr/bin/ptyxis" ]] ||
    fail "Ptyxis missing"

ptyxis_desktop="${ROOTFS_DIR}/usr/share/applications/org.gnome.Ptyxis.desktop"

[[ -f "${ptyxis_desktop}" ]] ||
    fail "Ptyxis desktop entry missing"

xdg_terminals="${ROOTFS_DIR}/etc/xdg/xdg-terminals.list"

[[ -f "${xdg_terminals}" ]] ||
    fail "XDG terminal preference missing"

grep -qx 'org.gnome.Ptyxis.desktop:new-window' "${xdg_terminals}" ||
    fail "Ptyxis is not the XDG default terminal"

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

colorizer_root="${ROOTFS_DIR}/usr/share/plasma/plasmoids/luisbocanegra.panel.colorizer"
colorizer_doc="${ROOTFS_DIR}/usr/share/doc/iulinux/third-party/panel-colorizer"
dock_preset="${colorizer_root}/contents/ui/presets/IULinux Dock/settings.json"
layout="${ROOTFS_DIR}/usr/share/plasma/look-and-feel/com.iulinux.desktop/contents/layouts/org.kde.plasma.desktop-layout.js"

[[ -f "${colorizer_root}/metadata.json" ]] ||
    fail "Panel Colorizer metadata missing"

grep -Eq '"Id"[[:space:]]*:[[:space:]]*"luisbocanegra\.panel\.colorizer"'     "${colorizer_root}/metadata.json" ||
    fail "Panel Colorizer plugin ID mismatch"

grep -Eq '"Version"[[:space:]]*:[[:space:]]*"8\.0\.0"'     "${colorizer_root}/metadata.json" ||
    fail "Panel Colorizer version mismatch"

grep -Eq '"License"[[:space:]]*:[[:space:]]*"GPL-3\.0"'     "${colorizer_root}/metadata.json" ||
    fail "Panel Colorizer license metadata mismatch"

[[ -f "${colorizer_doc}/LICENSE" ]] ||
    fail "Panel Colorizer license file missing"

[[ -f "${colorizer_doc}/NOTICE" ]] ||
    fail "Panel Colorizer notice missing"

[[ -f "${dock_preset}" ]] ||
    fail "IULinux Dock preset missing"

dock_sha256="$(
    sha256sum "${dock_preset}" |
        awk '{print $1}'
)"

[[ "${dock_sha256}" == "617cb212687b4d6106d384106c24b0366e4579066bebe18ccf4afdd2dfd1bdc0" ]] ||
    fail "IULinux Dock preset checksum mismatch"

[[ -f "${layout}" ]] ||
    fail "IULinux Plasma layout missing"

[[ "$(grep -c '^[[:space:]]*addGap();[[:space:]]*$' "${layout}")" -eq 2 ]] ||
    fail "IULinux dock does not contain exactly two spacer boundaries"

grep -A1 '"length",' "${layout}" |
    grep -Eq '^[[:space:]]*40[[:space:]]*$' ||
    fail "IULinux dock spacer length is not 40 px"

grep -Fq 'tasks.currentConfigGroup = ["General"];' "${layout}" ||
    fail "Icons-only Task Manager configuration group is not General"

! grep -Fq '"separateLaunchers"' "${layout}" ||
    fail "Icons-only Task Manager contains unsupported separateLaunchers override"

grep -Fq '"luisbocanegra.panel.colorizer"' "${layout}" ||
    fail "Panel Colorizer is not present in IULinux panel layout"

grep -A1 '"hideWidget",' "${layout}" |
    grep -Eq '^[[:space:]]*true[[:space:]]*$' ||
    fail "Panel Colorizer controller is not hidden"

grep -A1 '"islandsEnabled",' "${layout}" |
    grep -Eq '^[[:space:]]*true[[:space:]]*$' ||
    fail "Panel Colorizer widget islands are not enabled"

grep -A1 '"islandSeparatorWidget",' "${layout}" |
    grep -Fq '"org.kde.plasma.panelspacer"' ||
    fail "Panel Colorizer does not use native Plasma spacers"

grep -A1 '"islandSeparatorPairing",' "${layout}" |
    grep -Eq '^[[:space:]]*false[[:space:]]*$' ||
    fail "Panel Colorizer separator pairing is enabled"

grep -A1 '"blacklistIslandSeparator",' "${layout}" |
    grep -Eq '^[[:space:]]*true[[:space:]]*$' ||
    fail "Panel Colorizer spacer blacklist is disabled"

grep -Fq '/usr/share/plasma/plasmoids/luisbocanegra.panel.colorizer/contents/ui/presets/IULinux Dock'     "${layout}" ||
    fail "IULinux Dock preset is not configured for automatic loading"

terminal="$(
    readlink \
        "${ROOTFS_DIR}/etc/alternatives/x-terminal-emulator" \
        2>/dev/null || true
)"

[[ "${terminal}" == "/usr/bin/xdg-terminal-exec" ]] ||
    fail "xdg-terminal-exec is not the legacy terminal compatibility bridge"

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
