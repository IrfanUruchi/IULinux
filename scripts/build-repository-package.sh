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

src="${PROJECT_ROOT}/packaging/iulinux-repository"
template="${src}/templates/iulinux.sources"
stage="$(mktemp -d)"
output="${stage}/rootfs/etc/apt/sources.list.d/iulinux.sources"

cleanup()
{
    rm -rf "${stage}"
}
trap cleanup EXIT

[[ -f "${template}" ]] || {
    echo "[FAIL] Missing repository source template."
    exit 1
}

cp -a "${src}/." "${stage}/"
mkdir -p "$(dirname "${output}")"

sed "s|@IULINUX_REPOSITORY_URI@|${URI}|g" \
    "${template}" > "${output}"

"${PROJECT_ROOT}/scripts/build-deb.sh" \
    iulinux-repository \
    "${stage}"

echo "[PASS] Built IULinux repository bootstrap"
echo "URI: ${URI}"
