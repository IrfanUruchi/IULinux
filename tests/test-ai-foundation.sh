#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${PROJECT_ROOT}/build/rootfs"

fail()
{
    echo "[FAIL] IULinux AI foundation: $*"
    exit 1
}

PACKAGES=(
    pipx
    libopenblas-dev
    libgomp1
    libcurl4-openssl-dev
    libssl-dev
    libnuma-dev
    numactl
    hwloc
)

for pkg in "${PACKAGES[@]}"; do
    status="$(
        sudo chroot "${ROOTFS}" \
            dpkg-query -W -f='${db:Status-Abbrev}' "${pkg}" \
            2>/dev/null || true
    )"

    [[ "${status}" == "ii " ]] ||
        fail "${pkg} not installed"
done

for bin in pipx numactl hwloc-info; do
    [[ -x "${ROOTFS}/usr/bin/${bin}" ]] ||
        fail "${bin} missing"
done

[[ -x "${ROOTFS}/usr/bin/iulinux-ai-init" ]] ||
    fail "iulinux-ai-init missing"

"${PROJECT_ROOT}/scripts/chroot-run.sh" \
    pkg-config --exists openblas ||
    fail "OpenBLAS development interface unavailable"

"${PROJECT_ROOT}/scripts/chroot-run.sh" \
    pkg-config --exists libcurl ||
    fail "libcurl development interface unavailable"

"${PROJECT_ROOT}/scripts/chroot-run.sh" \
    pkg-config --exists openssl ||
    fail "OpenSSL development interface unavailable"

echo "[PASS] IULinux AI workstation foundation"
