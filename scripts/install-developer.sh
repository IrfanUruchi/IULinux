#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_LIST="${PROJECT_ROOT}/packages/developer.list"

[[ -f "${PACKAGE_LIST}" ]] || {
    echo "[IULinux] Missing developer package list." >&2
    exit 1
}

mapfile -t PACKAGES < <(
    sed \
        -e 's/#.*$//' \
        -e '/^[[:space:]]*$/d' \
        "${PACKAGE_LIST}"
)

echo "============================================"
echo " IULinux developer workstation"
echo "============================================"
echo "Packages: ${#PACKAGES[@]}"

"${PROJECT_ROOT}/scripts/chroot-run.sh" \
    env DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends "${PACKAGES[@]}"

echo
echo "[IULinux] Developer workstation installed."
