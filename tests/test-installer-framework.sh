#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"

fail()
{
    echo "[FAIL] $*" >&2
    exit 1
}

package_status()
{
    dpkg-query \
        --admindir="${ROOTFS_DIR}/var/lib/dpkg" \
        -W \
        -f='${db:Status-Abbrev}' \
        "$1" 2>/dev/null || true
}

[[ "$(package_status calamares)" == "ii " ]] ||
    fail "Calamares is not installed"

[[ -x "${ROOTFS_DIR}/usr/bin/calamares" ]] ||
    fail "Calamares executable missing"

# IULinux must own the installer identity.
for foreign_settings in \
    calamares-settings-kubuntu \
    calamares-settings-lubuntu \
    calamares-settings-ubuntu-unity \
    calamares-settings-debian \
    calamares-settings-mobian
do
    [[ "$(package_status "${foreign_settings}")" != "ii " ]] ||
        fail "Foreign installer settings installed: ${foreign_settings}"
done

module_count="$(
    find \
        "${ROOTFS_DIR}/usr/lib" \
        -type f \
        -name module.desc \
        -path '*calamares*' \
        2>/dev/null |
        wc -l
)"

(( module_count > 0 )) ||
    fail "No Calamares modules found"

echo "[PASS] IULinux installer framework (${module_count} modules)"
