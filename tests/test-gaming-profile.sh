#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${PROJECT_ROOT}/build/rootfs"
PROFILE_ROOT="${ROOTFS}/usr/share/iulinux/profiles/gaming"

fail()
{
    echo "[FAIL] IULinux Gaming profile: $*"
    exit 1
}

[[ -f "${PROFILE_ROOT}/profile.conf" ]] ||
    fail "profile manifest missing"

[[ -f "${PROFILE_ROOT}/packages.list" ]] ||
    fail "package manifest missing"

[[ -f "${PROFILE_ROOT}/architectures.list" ]] ||
    fail "architecture manifest missing"

grep -qx 'i386' "${PROFILE_ROOT}/architectures.list" ||
    fail "i386 architecture requirement missing"

list_output="$("${PROJECT_ROOT}/scripts/chroot-run.sh" iulinux-profile list)"
grep -q '^gaming' <<<"${list_output}" ||
    fail "profile not listed"

info_output="$("${PROJECT_ROOT}/scripts/chroot-run.sh" iulinux-profile info gaming)"
grep -q 'Default:     false' <<<"${info_output}" ||
    fail "profile incorrectly marked default"

plan_output="$("${PROJECT_ROOT}/scripts/chroot-run.sh" iulinux-profile plan gaming)"

for pkg in \
    steam-installer \
    steam-devices \
    gamemode \
    mangohud \
    gamescope \
    vkbasalt
do
    grep -q "${pkg}" <<<"${plan_output}" ||
        fail "missing package in plan: ${pkg}"
done

grep -q 'Required architectures:' <<<"${plan_output}" ||
    fail "architecture section missing from plan"

grep -q '  i386' <<<"${plan_output}" ||
    fail "i386 missing from plan"

status_output="$("${PROJECT_ROOT}/scripts/chroot-run.sh" iulinux-profile status gaming)"
grep -q 'not installed' <<<"${status_output}" ||
    fail "profile unexpectedly installed"

if "${PROJECT_ROOT}/scripts/chroot-run.sh" \
    dpkg --print-foreign-architectures |
    grep -qx 'i386'
then
    fail "i386 leaked into default rootfs"
fi

for pkg in \
    steam-installer \
    steam-devices \
    gamemode \
    mangohud \
    gamescope \
    vkbasalt
do
    status="$(
        "${PROJECT_ROOT}/scripts/chroot-run.sh" \
            dpkg-query -W -f='${db:Status-Abbrev}' \
            "${pkg}" 2>/dev/null || true
    )"

    [[ "${status}" != ii* ]] ||
        fail "Gaming package leaked into default rootfs: ${pkg}"
done

echo "[PASS] IULinux Gaming profile"
