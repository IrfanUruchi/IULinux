#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ISO="${PROJECT_ROOT}/build/IULinux-0.1-dev-amd64.iso"
DISK="${PROJECT_ROOT}/build/vm/iulinux-uefi-install-test.qcow2"
VARS="${PROJECT_ROOT}/build/vm/iulinux-uefi-vars.fd"

MODE="${1:-install}"

# Locate OVMF.
for candidate in \
    /usr/share/OVMF/OVMF_CODE_4M.fd \
    /usr/share/OVMF/OVMF_CODE.fd
do
    if [[ -f "${candidate}" ]]; then
        OVMF_CODE="${candidate}"
        break
    fi
done

for candidate in \
    /usr/share/OVMF/OVMF_VARS_4M.fd \
    /usr/share/OVMF/OVMF_VARS.fd
do
    if [[ -f "${candidate}" ]]; then
        OVMF_VARS_TEMPLATE="${candidate}"
        break
    fi
done

[[ -n "${OVMF_CODE:-}" && -n "${OVMF_VARS_TEMPLATE:-}" ]] || {
    echo "[IULinux] OVMF firmware missing."
    echo "Install it with: sudo apt install ovmf"
    exit 1
}

mkdir -p "${PROJECT_ROOT}/build/vm"

ACCEL=(-accel tcg)

if [[ -r /dev/kvm && -w /dev/kvm ]]; then
    ACCEL=(-accel kvm)
    echo "[IULinux] KVM acceleration enabled."
fi

COMMON=(
    -name "IULinux UEFI Install Test"
    -machine q35
    "${ACCEL[@]}"
    -m 4096
    -smp 4
    -device virtio-vga

    -drive "if=pflash,format=raw,readonly=on,file=${OVMF_CODE}"
    -drive "if=pflash,format=raw,file=${VARS}"

    -drive "file=${DISK},format=qcow2,if=virtio,cache=writeback"

    -netdev user,id=net0
    -device virtio-net-pci,netdev=net0
)

case "${MODE}" in

    reset)
        echo "[IULinux] Creating fresh UEFI test environment..."

        rm -f "${DISK}" "${VARS}"

        qemu-img create \
            -f qcow2 \
            "${DISK}" \
            64G

        cp "${OVMF_VARS_TEMPLATE}" "${VARS}"

        echo
        echo "[PASS] Fresh 64 GiB UEFI test disk created."
        echo "[PASS] Fresh OVMF NVRAM created."
        ;;

    install)
        [[ -f "${ISO}" ]] || {
            echo "[IULinux] ISO missing: ${ISO}" >&2
            exit 1
        }

        [[ -f "${DISK}" && -f "${VARS}" ]] || {
            echo "[IULinux] Run '$0 reset' first." >&2
            exit 1
        }

        echo "[IULinux] Booting IULinux installer in UEFI mode."

        exec qemu-system-x86_64 \
            "${COMMON[@]}" \
            -cdrom "${ISO}" \
            -boot order=c,once=d,menu=on
        ;;

    disk)
        [[ -f "${DISK}" && -f "${VARS}" ]] || {
            echo "[IULinux] UEFI test environment missing." >&2
            exit 1
        }

        echo "[IULinux] Booting installed UEFI disk WITHOUT ISO."

        exec qemu-system-x86_64 \
            "${COMMON[@]}" \
            -boot order=c,menu=on
        ;;

    *)
        echo "Usage: $0 {reset|install|disk}" >&2
        exit 2
        ;;
esac
