#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_LIST="${PROJECT_ROOT}/packages/gpu-base.list"

mapfile -t PACKAGES < <(
    sed \
        -e 's/#.*$//' \
        -e '/^[[:space:]]*$/d' \
        "${PACKAGE_LIST}"
)

echo "============================================"
echo " IULinux GPU foundation"
echo "============================================"

echo "[IULinux] Validating package availability..."

for pkg in "${PACKAGES[@]}"; do
    candidate="$(
        "${PROJECT_ROOT}/scripts/chroot-run.sh" \
            apt-cache policy "${pkg}" |
        awk '/Candidate:/ {print $2; exit}'
    )"

    if [[ -z "${candidate}" || "${candidate}" == "(none)" ]]; then
        echo "[FAIL] No candidate for ${pkg}" >&2
        exit 1
    fi

    printf "  %-28s %s\n" "${pkg}" "${candidate}"
done

"${PROJECT_ROOT}/scripts/chroot-run.sh" \
    env DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends "${PACKAGES[@]}"

echo
echo "[IULinux] GPU foundation installed."
