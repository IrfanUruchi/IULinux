#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${PROJECT_ROOT}/build/rootfs"

fail()
{
    echo "[FAIL] IULinux workstation controls: $*"
    exit 1
}

for pkg in \
    systemsettings \
    kscreen \
    plasma-nm \
    plasma-pa \
    bluez \
    bluedevil
do
    "${PROJECT_ROOT}/scripts/chroot-run.sh" dpkg -s "${pkg}" >/dev/null 2>&1 ||
        fail "${pkg} missing"
done

"${PROJECT_ROOT}/scripts/chroot-run.sh" bash -c \
    "dpkg -L kscreen | grep -Eq 'kcm.*kscreen|kscreen.*kcm'" ||
    fail "KScreen Display Configuration module missing"

[[ -f "${ROOTFS}/usr/lib/systemd/system/bluetooth.service" ]] ||
    fail "Bluetooth service missing"

echo "[PASS] IULinux workstation controls"
