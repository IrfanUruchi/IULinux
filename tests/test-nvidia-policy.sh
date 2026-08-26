#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${PROJECT_ROOT}/build/rootfs"

fail()
{
    echo "[FAIL] IULinux NVIDIA policy: $*"
    exit 1
}

[[ -x "${ROOTFS}/usr/bin/iulinux-nvidia-setup" ]] ||
    fail "NVIDIA setup utility missing"

bash -n "${ROOTFS}/usr/bin/iulinux-nvidia-setup" ||
    fail "NVIDIA setup utility syntax"

# Generic IULinux must NEVER carry a proprietary NVIDIA driver by default.
if sudo chroot "${ROOTFS}" dpkg-query -W \
    -f='${binary:Package} ${db:Status-Abbrev}\n' \
    'nvidia-driver-*' 2>/dev/null |
    grep -E '^nvidia-driver-.* ii ' >/dev/null
then
    fail "NVIDIA driver unexpectedly present in generic image"
fi

grep -q 'ubuntu-drivers install' \
    "${ROOTFS}/usr/bin/iulinux-nvidia-setup" ||
    fail "Ubuntu recommended-driver mechanism missing"

grep -q '10de:' \
    "${ROOTFS}/usr/bin/iulinux-nvidia-setup" ||
    fail "NVIDIA PCI hardware gate missing"

"${PROJECT_ROOT}/scripts/chroot-run.sh" \
    /usr/bin/iulinux-nvidia-setup --check

echo "[PASS] IULinux NVIDIA optional-driver policy"
