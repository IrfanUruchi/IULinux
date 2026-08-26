#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ISO="${PROJECT_ROOT}/build/IULinux-0.1-dev-amd64.iso"
DISK="${PROJECT_ROOT}/build/vm/iulinux-install-test.qcow2"

MODE="${1:-install}"

[[ -f "${DISK}" ]] || {
    echo "[IULinux] Install-test disk missing: ${DISK}" >&2
    exit 1
}

command -v qemu-system-x86_64 >/dev/null || {
    echo "[IULinux] qemu-system-x86_64 missing." >&2
    exit 1
}

ACCEL=()

if [[ -r /dev/kvm && -w /dev/kvm ]]; then
    echo "[IULinux] KVM acceleration enabled."
    ACCEL=(-accel kvm)
else
    echo "[IULinux] KVM unavailable; using TCG."
    ACCEL=(-accel tcg)
fi

COMMON=(
    -name "IULinux Install Test"
    -machine q35
    "${ACCEL[@]}"
    -m 4096
    -smp 4
    -device virtio-vga
    -audiodev pipewire,id=audio0
    -device ich9-intel-hda
    -device hda-duplex,audiodev=audio0

    -drive "file=${DISK},format=qcow2,if=virtio,cache=writeback"

    -netdev user,id=net0
    -device virtio-net-pci,netdev=net0
)

case "${MODE}" in
    install)
        [[ -f "${ISO}" ]] || {
            echo "[IULinux] ISO missing: ${ISO}" >&2
            exit 1
        }

        echo "[IULinux] Booting live ISO with sacrificial 64 GiB disk."

        exec qemu-system-x86_64 \
            "${COMMON[@]}" \
            -cdrom "${ISO}" \
            -boot order=c,once=d,menu=on
        ;;

    disk)
        echo "[IULinux] Booting installed disk WITHOUT live ISO."

        exec qemu-system-x86_64 \
            "${COMMON[@]}" \
            -boot order=c,menu=on
        ;;

    *)
        echo "Usage: $0 [install|disk]" >&2
        exit 2
        ;;
esac
