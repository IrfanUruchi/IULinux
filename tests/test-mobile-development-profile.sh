#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${PROJECT_ROOT}/build/rootfs"
PROFILE_ROOT="${ROOTFS}/usr/share/iulinux/profiles/mobile-development"

fail() {
    echo "[FAIL] IULinux Mobile Development profile: $*"
    exit 1
}

[[ -f "${PROFILE_ROOT}/profile.conf" ]] ||
    fail "profile manifest missing"

[[ -f "${PROFILE_ROOT}/packages.list" ]] ||
    fail "package manifest missing"

[[ ! -e "${PROFILE_ROOT}/architectures.list" ]] ||
    fail "unexpected architecture manifest"

list="$("${PROJECT_ROOT}/scripts/chroot-run.sh" iulinux-profile list)"
grep -q '^mobile-development' <<<"${list}" ||
    fail "profile not listed"

info="$("${PROJECT_ROOT}/scripts/chroot-run.sh" iulinux-profile info mobile-development)"
grep -q 'Default:     false' <<<"${info}" ||
    fail "profile incorrectly marked default"

plan="$("${PROJECT_ROOT}/scripts/chroot-run.sh" iulinux-profile plan mobile-development)"

for pkg in \
    adb \
    fastboot \
    android-sdk-platform-tools-common \
    openjdk-21-jdk \
    scrcpy
do
    grep -q "${pkg}" <<<"${plan}" ||
        fail "missing package in plan: ${pkg}"
done

grep -q 'Required architectures:' <<<"${plan}" ||
    fail "architecture section missing"

grep -q '  none' <<<"${plan}" ||
    fail "unexpected architecture requirement"

status="$("${PROJECT_ROOT}/scripts/chroot-run.sh" iulinux-profile status mobile-development)"
grep -q 'not installed' <<<"${status}" ||
    fail "profile unexpectedly installed"

for pkg in \
    adb \
    fastboot \
    android-sdk-platform-tools-common \
    android-udev-rules \
    openjdk-21-jdk \
    scrcpy
do
    state="$(
        "${PROJECT_ROOT}/scripts/chroot-run.sh" \
            dpkg-query -W -f='${db:Status-Abbrev}' \
            "${pkg}" 2>/dev/null || true
    )"

    [[ "${state}" != ii* ]] ||
        fail "Mobile Development package leaked into default rootfs: ${pkg}"
done

echo "[PASS] IULinux Mobile Development profile"
