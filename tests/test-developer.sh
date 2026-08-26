#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${PROJECT_ROOT}/build/rootfs"

fail()
{
    echo "[FAIL] IULinux developer workstation"
    exit 1
}

for bin in \
    git \
    gcc \
    g++ \
    make \
    gdb \
    clang \
    ld.lld \
    lldb \
    cmake \
    ninja \
    meson \
    pkg-config \
    ccache \
    python3 \
    pip3 \
    jq \
    rg \
    strace
do
    [[ -x "${ROOTFS}/usr/bin/${bin}" ]] || fail
done

[[ -f "${ROOTFS}/usr/include/Python.h" ]] || {
    # Python headers live in a versioned directory.
    find "${ROOTFS}/usr/include" \
        -maxdepth 2 \
        -name Python.h \
        -print -quit 2>/dev/null |
        grep -q . || fail
}

echo "[PASS] IULinux developer workstation"
