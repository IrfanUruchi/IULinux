#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"

fail()
{
    echo "[FAIL] $*" >&2
    exit 1
}

NETPLAN="${ROOTFS_DIR}/etc/netplan/01-iulinux-network-manager.yaml"
NM_OVERRIDE="${ROOTFS_DIR}/etc/NetworkManager/conf.d/10-globally-managed-devices.conf"

[[ -f "${NETPLAN}" ]] ||
    fail "IULinux Netplan policy missing"

sudo grep -qE '^[[:space:]]*renderer:[[:space:]]*NetworkManager[[:space:]]*$' \
    "${NETPLAN}" ||
    fail "NetworkManager is not the Netplan renderer"

[[ "$(sudo stat -c '%a' "${NETPLAN}")" == "600" ]] ||
    fail "Netplan configuration permissions are not 600"

[[ -f "${NM_OVERRIDE}" ]] ||
    fail "NetworkManager managed-device override missing"

grep -qE '^[[:space:]]*unmanaged-devices=none[[:space:]]*$' \
    "${NM_OVERRIDE}" ||
    fail "NetworkManager Ethernet ownership override missing"

echo "[PASS] IULinux network policy"
