#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"
FORBIDDEN_LIST="${PROJECT_ROOT}/packages/forbidden.list"

fail()
{
    echo "[FAIL] $*" >&2
    exit 1
}

[[ -d "${ROOTFS_DIR}" ]] ||
    fail "Rootfs missing"

[[ -f "${FORBIDDEN_LIST}" ]] ||
    fail "Forbidden package manifest missing"

mapfile -t FORBIDDEN < <(
    sed \
        -e 's/[[:space:]]*#.*$//' \
        -e '/^[[:space:]]*$/d' \
        "${FORBIDDEN_LIST}"
)

for package in "${FORBIDDEN[@]}"; do
    status="$(
        dpkg-query \
            --admindir="${ROOTFS_DIR}/var/lib/dpkg" \
            -W \
            -f='${db:Status-Abbrev}' \
            "${package}" 2>/dev/null || true
    )"

    if [[ "${status}" == "ii " ]]; then
        fail "Forbidden package installed: ${package}"
    fi
done

echo "[PASS] IULinux lean package policy"
