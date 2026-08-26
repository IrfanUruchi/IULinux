#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${PROJECT_ROOT}/build/rootfs"

fail()
{
    echo "[FAIL] IULinux NVIDIA container policy: $*"
    exit 1
}

TOOL="${ROOTFS}/usr/bin/iulinux-nvidia-container-setup"

[[ -x "${TOOL}" ]] ||
    fail "setup utility missing"

bash -n "${TOOL}" ||
    fail "setup utility syntax"

grep -q '10de:' "${TOOL}" ||
    fail "NVIDIA PCI gate missing"

grep -q 'nvidia-ctk runtime configure --runtime=docker' "${TOOL}" ||
    fail "Docker runtime configuration missing"

grep -q 'nvidia.github.io/libnvidia-container' "${TOOL}" ||
    fail "official NVIDIA repository missing"

# Generic image must not include NVIDIA Container Toolkit by default.
status="$(
    sudo chroot "${ROOTFS}" \
        dpkg-query -W -f='${db:Status-Abbrev}' \
        nvidia-container-toolkit 2>/dev/null || true
)"

[[ "${status}" != "ii " ]] ||
    fail "NVIDIA Container Toolkit unexpectedly installed by default"

"${PROJECT_ROOT}/scripts/chroot-run.sh" \
    /usr/bin/iulinux-nvidia-container-setup --check

echo "[PASS] IULinux NVIDIA container policy"
