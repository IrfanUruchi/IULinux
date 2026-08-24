#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"

fail()
{
    echo "[FAIL] $*" >&2
    exit 1
}

status="$(
    dpkg-query \
        --admindir="${ROOTFS_DIR}/var/lib/dpkg" \
        -W \
        -f='${db:Status-Abbrev}' \
        brave-browser 2>/dev/null || true
)"

[[ "${status}" == "ii " ]] ||
    fail "Brave Browser is not installed"

[[ -x "${ROOTFS_DIR}/usr/bin/brave-browser" ]] ||
    fail "Brave executable missing"

[[ -f "${ROOTFS_DIR}/usr/share/applications/brave-browser.desktop" ]] ||
    fail "Brave desktop entry missing"

MIME="${ROOTFS_DIR}/etc/xdg/mimeapps.list"

[[ -f "${MIME}" ]] ||
    fail "IULinux MIME defaults missing"

grep -qx 'x-scheme-handler/http=brave-browser.desktop' "${MIME}" ||
    fail "Brave is not the HTTP default"

grep -qx 'x-scheme-handler/https=brave-browser.desktop' "${MIME}" ||
    fail "Brave is not the HTTPS default"

grep -qx 'text/html=brave-browser.desktop' "${MIME}" ||
    fail "Brave is not the HTML default"

echo "[PASS] IULinux Brave Browser policy"
