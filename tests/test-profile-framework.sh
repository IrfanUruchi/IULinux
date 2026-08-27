#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${PROJECT_ROOT}/build/rootfs"

fail()
{
    echo "[FAIL] IULinux profile framework: $*"
    exit 1
}

[[ -x "${ROOTFS}/usr/bin/iulinux-profile" ]] ||
    fail "profile CLI missing"

[[ -f "${ROOTFS}/usr/share/iulinux/profiles/ai/profile.conf" ]] ||
    fail "AI profile manifest missing"

bash -n "${ROOTFS}/usr/bin/iulinux-profile" ||
    fail "profile CLI syntax"

"${PROJECT_ROOT}/scripts/chroot-run.sh" \
    /usr/bin/iulinux-profile list |
    grep -q '^ai' ||
    fail "AI profile not listed"

"${PROJECT_ROOT}/scripts/chroot-run.sh" \
    /usr/bin/iulinux-profile info ai |
    grep -q 'Default:     false' ||
    fail "AI profile incorrectly marked default"

echo "[PASS] IULinux profile framework"
