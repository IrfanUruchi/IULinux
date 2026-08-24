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
        onlyoffice-desktopeditors 2>/dev/null || true
)"

[[ "${status}" == "ii " ]] ||
    fail "ONLYOFFICE Desktop Editors is not installed"

[[ -x "${ROOTFS_DIR}/usr/bin/desktopeditors" ]] ||
    fail "ONLYOFFICE executable missing"

DESKTOP_ENTRY="${ROOTFS_DIR}/usr/share/applications/onlyoffice-desktopeditors.desktop"

[[ -f "${DESKTOP_ENTRY}" ]] ||
    fail "ONLYOFFICE desktop entry missing"

for forbidden in \
    libreoffice \
    libreoffice-core \
    libreoffice-common
do
    state="$(
        dpkg-query \
            --admindir="${ROOTFS_DIR}/var/lib/dpkg" \
            -W \
            -f='${db:Status-Abbrev}' \
            "${forbidden}" 2>/dev/null || true
    )"

    [[ "${state}" != "ii " ]] ||
        fail "Forbidden office package installed: ${forbidden}"
done

MIME="${ROOTFS_DIR}/etc/xdg/mimeapps.list"

[[ -f "${MIME}" ]] ||
    fail "IULinux MIME defaults missing"

required_defaults=(
    'application/msword=onlyoffice-desktopeditors.desktop'
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document=onlyoffice-desktopeditors.desktop'
    'application/vnd.ms-excel=onlyoffice-desktopeditors.desktop'
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet=onlyoffice-desktopeditors.desktop'
    'application/vnd.ms-powerpoint=onlyoffice-desktopeditors.desktop'
    'application/vnd.openxmlformats-officedocument.presentationml.presentation=onlyoffice-desktopeditors.desktop'
    'application/vnd.oasis.opendocument.text=onlyoffice-desktopeditors.desktop'
    'application/vnd.oasis.opendocument.spreadsheet=onlyoffice-desktopeditors.desktop'
    'application/vnd.oasis.opendocument.presentation=onlyoffice-desktopeditors.desktop'
)

for association in "${required_defaults[@]}"; do
    grep -qxF "${association}" "${MIME}" ||
        fail "Missing ONLYOFFICE default: ${association}"
done

# Do not hijack generic reading/editing formats.
if grep -qxF 'application/pdf=onlyoffice-desktopeditors.desktop' "${MIME}"; then
    fail "ONLYOFFICE must not hijack PDF by default"
fi

if grep -qxF 'text/plain=onlyoffice-desktopeditors.desktop' "${MIME}"; then
    fail "ONLYOFFICE must not hijack plain text"
fi

if grep -qxF 'text/markdown=onlyoffice-desktopeditors.desktop' "${MIME}"; then
    fail "ONLYOFFICE must not hijack Markdown"
fi

echo "[PASS] IULinux ONLYOFFICE policy"
