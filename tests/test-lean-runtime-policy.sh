#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"

fail()
{
    echo "[FAIL] $*" >&2
    exit 1
}

BALOO="${ROOTFS_DIR}/etc/xdg/baloofilerc"

[[ -f "${BALOO}" ]] ||
    fail "IULinux Baloo policy missing"

grep -qE '^Indexing-Enabled=false$' "${BALOO}" ||
    fail "Baloo indexing is not disabled by default"

echo "[PASS] IULinux lean runtime policy"
