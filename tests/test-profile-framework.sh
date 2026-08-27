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

"${PROJECT_ROOT}/scripts/chroot-run.sh" \
    iulinux-profile list |
    grep -q '^ai' ||
    fail "AI profile not listed"

"${PROJECT_ROOT}/scripts/chroot-run.sh" \
    iulinux-profile info ai |
    grep -q 'Default:     false' ||
    fail "AI profile incorrectly marked default"

"${PROJECT_ROOT}/scripts/chroot-run.sh" \
    iulinux-profile plan ai |
    grep -q 'llama.cpp' ||
    fail "AI installation plan incomplete"

"${PROJECT_ROOT}/scripts/chroot-run.sh" \
    iulinux-profile status ai |
    grep -q 'not installed' ||
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
