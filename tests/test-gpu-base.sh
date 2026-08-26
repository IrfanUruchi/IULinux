#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${PROJECT_ROOT}/build/rootfs"

fail()
{
    echo "[FAIL] IULinux GPU foundation: $*"
    exit 1
}

PACKAGES=(
    libgl1-mesa-dri
    mesa-utils
    libvulkan1
    mesa-vulkan-drivers
    vulkan-tools
)

for pkg in "${PACKAGES[@]}"; do
    status="$(
        sudo chroot "${ROOTFS}" \
            dpkg-query -W -f='${db:Status-Abbrev}' "${pkg}" \
            2>/dev/null || true
    )"

    [[ "${status}" == "ii " ]] ||
        fail "${pkg} not installed"
done

for bin in glxinfo glxgears vulkaninfo vkcube; do
    [[ -x "${ROOTFS}/usr/bin/${bin}" ]] ||
        fail "${bin} missing"
done

[[ -d "${ROOTFS}/usr/share/vulkan/icd.d" ]] ||
    fail "Vulkan ICD directory missing"

find "${ROOTFS}/usr/share/vulkan/icd.d" \
    -maxdepth 1 \
    -type f \
    -name '*.json' \
    -print -quit |
    grep -q . ||
    fail "No Vulkan ICD manifests"

echo "[PASS] IULinux GPU foundation"
