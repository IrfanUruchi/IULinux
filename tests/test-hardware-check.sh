#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${PROJECT_ROOT}/build/rootfs"
CHECK="${ROOTFS}/usr/bin/iulinux-hardware-check"

fail()
{
    echo "[FAIL] IULinux hardware checker: $*"
    exit 1
}

[[ -x "${CHECK}" ]] ||
    fail "hardware checker missing"

bash -n "${CHECK}" ||
    fail "hardware checker syntax"

for section in \
    "=== CPU ===" \
    "=== GRAPHICS ===" \
    "=== NETWORK ===" \
    "=== AUDIO ===" \
    "=== BLUETOOTH ===" \
    "=== STORAGE ===" \
    "=== USB ===" \
    "=== FAILED SERVICES ==="
do
    grep -Fq "${section}" "${CHECK}" ||
        fail "missing section: ${section}"
done

grep -Fq 'systemctl --failed' "${CHECK}" ||
    fail "failed-unit check missing"

echo "[PASS] IULinux physical hardware smoke checker"
