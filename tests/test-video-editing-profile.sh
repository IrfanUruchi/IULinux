#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${PROJECT_ROOT}/build/rootfs"
PROFILE_ROOT="${ROOTFS}/usr/share/iulinux/profiles/video-editing"

fail()
{
    echo "[FAIL] IULinux Video Editing profile: $*"
    exit 1
}

[[ -f "${PROFILE_ROOT}/profile.conf" ]] ||
    fail "profile manifest missing"

[[ -f "${PROFILE_ROOT}/packages.list" ]] ||
    fail "package manifest missing"

list_output="$("${PROJECT_ROOT}/scripts/chroot-run.sh" iulinux-profile list)"
grep -q '^video-editing' <<<"${list_output}" ||
    fail "profile not listed"

info_output="$("${PROJECT_ROOT}/scripts/chroot-run.sh" iulinux-profile info video-editing)"
grep -q 'Default:     false' <<<"${info_output}" ||
    fail "profile incorrectly marked default"

plan_output="$("${PROJECT_ROOT}/scripts/chroot-run.sh" iulinux-profile plan video-editing)"

for pkg in \
    kdenlive \
    ffmpeg \
    mediainfo \
    frei0r-plugins \
    handbrake
do
    grep -q "${pkg}" <<<"${plan_output}" ||
        fail "missing package in plan: ${pkg}"
done

grep -q 'Required architectures:' <<<"${plan_output}" ||
    fail "architecture section missing from plan"

grep -q '  none' <<<"${plan_output}" ||
    fail "unexpected architecture requirement"

status_output="$("${PROJECT_ROOT}/scripts/chroot-run.sh" iulinux-profile status video-editing)"
grep -q 'not installed' <<<"${status_output}" ||
    fail "profile unexpectedly installed"

for pkg in \
    kdenlive \
    ffmpeg \
    mediainfo \
    frei0r-plugins \
    handbrake
do
    status="$(
        "${PROJECT_ROOT}/scripts/chroot-run.sh" \
            dpkg-query -W -f='${db:Status-Abbrev}' \
            "${pkg}" 2>/dev/null || true
    )"

    [[ "${status}" != ii* ]] ||
        fail "Video Editing package leaked into default rootfs: ${pkg}"
done

echo "[PASS] IULinux Video Editing profile"
