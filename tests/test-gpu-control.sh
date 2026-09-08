#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${PROJECT_ROOT}/build/rootfs"

fail()
{
    echo "[FAIL] IULinux GPU control: $*"
    exit 1
}

GPU_TOOL="${ROOTFS}/usr/bin/iulinux-gpu"

[[ -x "${GPU_TOOL}" ]] ||
    fail "iulinux-gpu missing"

bash -n "${GPU_TOOL}" ||
    fail "iulinux-gpu syntax"

status_output="$(
    "${PROJECT_ROOT}/scripts/chroot-run.sh" \
        iulinux-gpu status
)"

grep -q '^Topology:' <<<"${status_output}" ||
    fail "topology missing from status"

grep -q '^Switching:' <<<"${status_output}" ||
    fail "switching state missing from status"

cap_output="$(
    "${PROJECT_ROOT}/scripts/chroot-run.sh" \
        iulinux-gpu capabilities
)"

for field in \
    'GPU count:' \
    'Intel GPU:' \
    'AMD GPU:' \
    'NVIDIA GPU:' \
    'NVIDIA userspace:' \
    'PRIME selector:' \
    'ASUS gfx backend:' \
    'Switch backend:' \
    'Switching modes:'
do
    grep -q "^${field}" <<<"${cap_output}" ||
        fail "capability field missing: ${field}"
done

for mode in hybrid integrated nvidia; do
    set +e
    mode_output="$(
        "${PROJECT_ROOT}/scripts/chroot-run.sh"             iulinux-gpu "${mode}" 2>&1
    )"
    rc=$?
    set -e

    (( rc != 0 )) ||
        fail "${mode} unexpectedly changed GPU state"

    grep -q '^\[FAIL\]' <<<"${mode_output}" ||
        fail "${mode} did not fail closed"
done

echo "[PASS] IULinux GPU switching interface fails closed"
echo "[PASS] IULinux GPU control foundation"
