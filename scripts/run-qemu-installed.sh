#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck disable=SC1091
source "${PROJECT_ROOT}/config/build.conf"

DISK="${PROJECT_ROOT}/build/iulinux-install-test.qcow2"


QEMU_ARGS=(
    -machine q35
    -m 4096
    -smp 4
    -boot order=c,menu=on
    -drive "file=${DISK},if=virtio,format=qcow2"
    -device virtio-vga
    -nic user,model=virtio-net-pci
)

if [[ -r /dev/kvm && -w /dev/kvm ]]; then
    echo "[IULinux] KVM acceleration enabled."
    QEMU_ARGS+=(
        -accel kvm
        -cpu host
    )
else
    echo "[IULinux] KVM unavailable to this user; using TCG."
    QEMU_ARGS+=(
        -accel tcg
        -cpu max
    )
fi

exec qemu-system-x86_64 "${QEMU_ARGS[@]}"
