#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${PROJECT_ROOT}/build/rootfs"

fail()
{
    echo "[FAIL] IULinux profile framework: $*"
    exit 1
}

PROFILE_ROOT="${ROOTFS}/usr/share/iulinux/profiles/ai"

[[ -x "${ROOTFS}/usr/bin/iulinux-profile" ]] ||
    fail "profile CLI missing"

[[ -f "${PROFILE_ROOT}/profile.conf" ]] ||
    fail "AI profile manifest missing"

[[ -f "${PROFILE_ROOT}/packages.list" ]] ||
    fail "AI profile package manifest missing"

[[ -x "${PROFILE_ROOT}/post-install" ]] ||
    fail "AI profile policy hook missing"

[[ -x "${PROFILE_ROOT}/overlay/usr/bin/iulinux-ai-init" ]] ||
    fail "AI init utility missing from dormant profile"

[[ -x "${PROFILE_ROOT}/overlay/usr/bin/iulinux-ai-info" ]] ||
    fail "AI info utility missing from dormant profile"

bash -n "${ROOTFS}/usr/bin/iulinux-profile" ||
    fail "profile CLI syntax"

bash -n "${PROFILE_ROOT}/post-install" ||
    fail "AI profile post-install syntax"

list_output="$(
    "${PROJECT_ROOT}/scripts/chroot-run.sh" \
        iulinux-profile list
)"

grep -q '^ai' <<<"${list_output}" ||
    fail "AI profile not listed"

info_output="$(
    "${PROJECT_ROOT}/scripts/chroot-run.sh" \
        iulinux-profile info ai
)"

grep -q 'Default:     false' <<<"${info_output}" ||
    fail "AI profile incorrectly marked default"

plan_output="$(
    "${PROJECT_ROOT}/scripts/chroot-run.sh" \
        iulinux-profile plan ai
)"

grep -q 'llama.cpp' <<<"${plan_output}" ||
    fail "AI installation plan incomplete"

status_output="$(
    "${PROJECT_ROOT}/scripts/chroot-run.sh" \
        iulinux-profile status ai
)"

grep -q 'not installed' <<<"${status_output}" ||
    fail "AI profile unexpectedly marked installed"

# Dormant profile assets must NOT become active default utilities.
[[ ! -e "${ROOTFS}/usr/bin/iulinux-ai-init" ]] ||
    fail "AI init leaked into default runtime"

[[ ! -e "${ROOTFS}/usr/bin/iulinux-ai-info" ]] ||
    fail "AI info leaked into default runtime"

# AI runtime must remain absent from default rootfs.
for pkg in \
    llama.cpp \
    llama.cpp-tools \
    libggml0-backend-blas \
    libggml0-backend-vulkan \
    pipx
do
    status="$(
        sudo chroot "${ROOTFS}" \
            dpkg-query -W -f='${db:Status-Abbrev}' "${pkg}" \
            2>/dev/null || true
    )"

    [[ "${status}" != "ii " ]] ||
        fail "${pkg} unexpectedly installed by default"
done

echo "[PASS] IULinux profile framework"

grep -q 'packages-before' \
    "${ROOTFS}/usr/bin/iulinux-profile" ||
    fail "package provenance snapshot missing"

grep -q 'packages-added' \
    "${ROOTFS}/usr/bin/iulinux-profile" ||
    fail "added-package provenance missing"

grep -q 'packages-preexisting' \
    "${ROOTFS}/usr/bin/iulinux-profile" ||
    fail "pre-existing package provenance missing"

grep -q 'overlay-files' \
    "${ROOTFS}/usr/bin/iulinux-profile" ||
    fail "overlay provenance missing"

grep -q 'check_overlay_collisions' \
    "${ROOTFS}/usr/bin/iulinux-profile" ||
    fail "overlay collision protection missing"

grep -Fq 'chmod 0755 "${final_state}"' \
    "${ROOTFS}/usr/bin/iulinux-profile" ||
    fail "profile state directory readability policy missing"

grep -Fq 'chmod 0644 {} +' \
    "${ROOTFS}/usr/bin/iulinux-profile" ||
    fail "profile state file readability policy missing"

echo "[PASS] IULinux profile state permission policy"

echo "[PASS] IULinux profile provenance policy"

[[ -x "${ROOTFS}/usr/lib/iulinux/profile-remove" ]] ||
    fail "profile removal engine missing"

bash -n "${ROOTFS}/usr/lib/iulinux/profile-remove" ||
    fail "profile removal engine syntax"

grep -q 'remove --no-auto-remove' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" ||
    fail "package removal safety gate missing"

grep -q 'Modified profile file preserved' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" ||
    fail "modified-file preservation missing"

grep -q 'Provenance archived' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" ||
    fail "removal provenance archive missing"

echo "[PASS] IULinux safe profile removal policy"

grep -q 'Autoremove would remove package not introduced by profile' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" ||
    fail "dependency autoremove safety gate missing"

[[ "$(
    grep -c '# Archive provenance instead of deleting profile history.' \
        "${ROOTFS}/usr/lib/iulinux/profile-remove"
)" -eq 1 ]] ||
    fail "profile remover must contain exactly one archive block"

echo "[PASS] IULinux profile lifecycle cleanup policy"
