#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${PROJECT_ROOT}/build/rootfs"
PROFILE_ROOT="${ROOTFS}/usr/share/iulinux/profiles/embedded"

fail()
{
    echo "[FAIL] IULinux Embedded profile: $*"
    exit 1
}

[[ -f "${PROFILE_ROOT}/profile.conf" ]] ||
    fail "profile manifest missing"

[[ -f "${PROFILE_ROOT}/packages.list" ]] ||
    fail "package manifest missing"

list_output="$("${PROJECT_ROOT}/scripts/chroot-run.sh" iulinux-profile list)"
grep -q '^embedded' <<<"${list_output}" ||
    fail "profile not listed"

info_output="$("${PROJECT_ROOT}/scripts/chroot-run.sh" iulinux-profile info embedded)"
grep -q 'Default:     false' <<<"${info_output}" ||
    fail "profile incorrectly marked default"

plan_output="$("${PROJECT_ROOT}/scripts/chroot-run.sh" iulinux-profile plan embedded)"

for pkg in \
    gcc-arm-none-eabi \
    gdb-multiarch \
    openocd \
    dfu-util \
    avrdude \
    picocom \
    python3-serial
do
    grep -q "${pkg}" <<<"${plan_output}" ||
        fail "missing package in plan: ${pkg}"
done

status_output="$("${PROJECT_ROOT}/scripts/chroot-run.sh" iulinux-profile status embedded)"
grep -q 'not installed' <<<"${status_output}" ||
    fail "profile unexpectedly installed"

echo "[PASS] IULinux Embedded Engineering profile"
