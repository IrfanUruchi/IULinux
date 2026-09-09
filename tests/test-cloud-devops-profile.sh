#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${PROJECT_ROOT}/build/rootfs"
PROFILE_ROOT="${ROOTFS}/usr/share/iulinux/profiles/cloud-devops"

fail() {
    echo "[FAIL] IULinux Cloud / DevOps profile: $*"
    exit 1
}

[[ -f "${PROFILE_ROOT}/profile.conf" ]] ||
    fail "profile manifest missing"

[[ -f "${PROFILE_ROOT}/packages.list" ]] ||
    fail "package manifest missing"

[[ ! -e "${PROFILE_ROOT}/architectures.list" ]] ||
    fail "unexpected architecture manifest"

list="$("${PROJECT_ROOT}/scripts/chroot-run.sh" iulinux-profile list)"
grep -q '^cloud-devops' <<<"${list}" ||
    fail "profile not listed"

info="$("${PROJECT_ROOT}/scripts/chroot-run.sh" iulinux-profile info cloud-devops)"
grep -q 'Default:     false' <<<"${info}" ||
    fail "profile incorrectly marked default"

plan="$("${PROJECT_ROOT}/scripts/chroot-run.sh" iulinux-profile plan cloud-devops)"

for pkg in \
    ansible-core \
    ansible-lint \
    awscli \
    skopeo \
    buildah \
    netavark
do
    grep -q "${pkg}" <<<"${plan}" ||
        fail "missing package in plan: ${pkg}"
done

grep -q 'Required architectures:' <<<"${plan}" ||
    fail "architecture section missing"

grep -q '  none' <<<"${plan}" ||
    fail "unexpected architecture requirement"

status="$("${PROJECT_ROOT}/scripts/chroot-run.sh" iulinux-profile status cloud-devops)"
grep -q 'not installed' <<<"${status}" ||
    fail "profile unexpectedly installed"

for pkg in \
    ansible-core \
    ansible-lint \
    awscli \
    skopeo \
    buildah \
    netavark \
    aardvark-dns \
    containernetworking-plugins
do
    state="$(
        "${PROJECT_ROOT}/scripts/chroot-run.sh" \
            dpkg-query -W -f='${db:Status-Abbrev}' \
            "${pkg}" 2>/dev/null || true
    )"

    [[ "${state}" != ii* ]] ||
        fail "Cloud / DevOps package leaked into default rootfs: ${pkg}"
done

echo "[PASS] IULinux Cloud / DevOps profile"
