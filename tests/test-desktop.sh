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
    plasma-desktop
    plasma-workspace
    plasma-session-wayland
    kwin-wayland
    sddm
    dolphin
    konsole
    plasma-nm
    plasma-pa
    pipewire
    wireplumber
    xwayland
)

for package in "${required_packages[@]}"; do
    status="$(
        dpkg-query \
            --admindir="${ROOTFS_DIR}/var/lib/dpkg" \
            -W \
            -f='${db:Status-Abbrev}' \
            "${package}" 2>/dev/null || true
    )"

    [[ "${status}" == "ii " ]] ||
        fail "Desktop package missing: ${package}"
done

[[ -x "${ROOTFS_DIR}/usr/bin/startplasma-wayland" ]] ||
    fail "startplasma-wayland missing"

[[ -x "${ROOTFS_DIR}/usr/bin/kwin_wayland" ]] ||
    fail "kwin_wayland missing"

[[ -x "${ROOTFS_DIR}/usr/bin/dolphin" ]] ||
    fail "Dolphin missing"

[[ -x "${ROOTFS_DIR}/usr/bin/konsole" ]] ||
    fail "Konsole missing"

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
