#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"
PACKAGING_DIR="${PROJECT_ROOT}/packaging"

fail()
{
    echo "[FAIL] $*" >&2
    exit 1
}

[[ -d "${ROOTFS_DIR}" ]] ||
    fail "Rootfs missing"

[[ -d "${PACKAGING_DIR}" ]] ||
    fail "Packaging directory missing"

shopt -s nullglob

controls=(
    "${PACKAGING_DIR}"/*/DEBIAN/control
)

(( ${#controls[@]} > 0 )) ||
    fail "No IULinux package control files found"

for control in "${controls[@]}"; do
    package="$(
        awk -F': *' '$1 == "Package" {print $2; exit}' \
            "${control}"
    )"

    source_version="$(
        awk -F': *' '$1 == "Version" {print $2; exit}' \
            "${control}"
    )"

    [[ -n "${package}" ]] ||
        fail "Package name missing in ${control}"

    [[ -n "${source_version}" ]] ||
        fail "Package version missing for ${package}"

    installed_version="$(
        sudo chroot "${ROOTFS_DIR}" \
            dpkg-query -W \
            -f='${Version}' \
            "${package}" \
            2>/dev/null
    )" ||
        fail "${package} is not installed in rootfs"

    installed_status="$(
        sudo chroot "${ROOTFS_DIR}" \
            dpkg-query -W \
            -f='${Status}' \
            "${package}" \
            2>/dev/null
    )" ||
        fail "Unable to query status for ${package}"

    [[ "${installed_status}" == "install ok installed" ]] ||
        fail "${package} is not fully installed: ${installed_status}"

    [[ "${installed_version}" == "${source_version}" ]] ||
        fail "${package} version drift: source=${source_version} rootfs=${installed_version}"

    echo "[PASS] ${package} ${source_version}"
done

audit="$(
    sudo chroot "${ROOTFS_DIR}" dpkg --audit
)"

[[ -z "${audit}" ]] || {
    echo "${audit}" >&2
    fail "Rootfs dpkg database requires attention"
}

echo "[PASS] IULinux package source/rootfs consistency"
