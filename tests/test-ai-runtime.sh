#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${PROJECT_ROOT}/build/rootfs"

fail()
{
    echo "[FAIL] IULinux native AI runtime: $*"
    exit 1
}

PACKAGES=(
    llama.cpp
    llama.cpp-tools
    libllama0
    libggml0
    libggml0-backend-blas
    libggml0-backend-vulkan
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

for bin in \
    llama-cli \
    llama-server \
    llama-bench \
    llama-quantize
do
    [[ -x "${ROOTFS}/usr/bin/${bin}" ]] ||
        fail "${bin} missing"
done

[[ -x "${ROOTFS}/usr/bin/iulinux-ai-info" ]] ||
    fail "iulinux-ai-info missing"

# GPU-vendor-heavy backend must remain optional.
status="$(
    sudo chroot "${ROOTFS}" \
        dpkg-query -W -f='${db:Status-Abbrev}' \
        libggml0-backend-hip 2>/dev/null || true
)"

[[ "${status}" != "ii " ]] ||
    fail "HIP backend unexpectedly installed by default"

# llama-server is available, but must never auto-start.
enabled="$(
    sudo chroot "${ROOTFS}" \
        systemctl is-enabled llama-server.service \
        2>/dev/null || true
)"

[[ "${enabled}" != "enabled" ]] ||
    fail "llama-server unexpectedly enabled"

echo "[PASS] IULinux native AI runtime"
