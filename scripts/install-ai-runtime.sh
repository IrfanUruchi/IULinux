#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGE_LIST="${PROJECT_ROOT}/packages/ai-runtime.list"

mapfile -t PACKAGES < <(
    sed \
        -e 's/#.*$//' \
        -e '/^[[:space:]]*$/d' \
        "${PACKAGE_LIST}"
)

echo "============================================"
echo " IULinux native AI runtime"
echo "============================================"

echo "[IULinux] Validating package availability..."

for pkg in "${PACKAGES[@]}"; do
    candidate="$(
        "${PROJECT_ROOT}/scripts/chroot-run.sh" \
            apt-cache policy "${pkg}" |
        awk '/Candidate:/ {print $2; exit}'
    )"

    [[ -n "${candidate}" && "${candidate}" != "(none)" ]] || {
        echo "[FAIL] No candidate for ${pkg}" >&2
        exit 1
    }

    printf "  %-28s %s\n" "${pkg}" "${candidate}"
done

"${PROJECT_ROOT}/scripts/chroot-run.sh" \
    env DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends "${PACKAGES[@]}"

# llama-server must never expose a service automatically.
"${PROJECT_ROOT}/scripts/chroot-run.sh" \
    systemctl disable llama-server.service >/dev/null 2>&1 || true

echo
echo "[IULinux] Native AI runtime installed."
