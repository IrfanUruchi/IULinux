#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${PROJECT_ROOT}/build/rootfs"
TOOL="${ROOTFS}/usr/bin/iulinux-cuda-setup"

fail()
{
    echo "[FAIL] IULinux CUDA policy: $*"
    exit 1
}

[[ -x "${TOOL}" ]] ||
    fail "CUDA setup utility missing"

bash -n "${TOOL}" ||
    fail "CUDA setup utility syntax"

grep -q 'cuda-toolkit-.*CUDA_SERIES' "${TOOL}" ||
    fail "version-pinned CUDA toolkit installation missing"

grep -q '10de:' "${TOOL}" ||
    fail "NVIDIA hardware gate missing"

# Generic IULinux must not ship CUDA by default.
if sudo chroot "${ROOTFS}" \
    dpkg-query -W -f='${binary:Package} ${db:Status-Abbrev}\n' \
    'cuda-toolkit-*' 2>/dev/null |
    grep -E '^cuda-toolkit-.* ii ' >/dev/null
then
    fail "CUDA toolkit unexpectedly present in generic image"
fi

"${PROJECT_ROOT}/scripts/chroot-run.sh" \
    /usr/bin/iulinux-cuda-setup --check

echo "[PASS] IULinux optional CUDA policy"
