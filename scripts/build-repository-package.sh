#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

URI="${1:-}"

[[ -n "${URI}" ]] || {
    echo "Usage: $0 <repository-uri>"
    exit 2
}

[[ "${URI}" == https://* ]] || {
    echo "[FAIL] Repository URI must use HTTPS."
    exit 1
}

template="${PROJECT_ROOT}/packaging/iulinux-repository/templates/iulinux.sources"
output="${PROJECT_ROOT}/packaging/iulinux-repository/rootfs/etc/apt/sources.list.d/iulinux.sources"

[[ -f "${template}" ]] || {
    echo "[FAIL] Missing repository source template."
    exit 1
}

mkdir -p "$(dirname "${output}")"

sed "s|@IULINUX_REPOSITORY_URI@|${URI}|g" \
    "${template}" > "${output}"

"${PROJECT_ROOT}/scripts/build-deb.sh" iulinux-repository

echo "[PASS] Built IULinux repository bootstrap"
echo "URI: ${URI}"
