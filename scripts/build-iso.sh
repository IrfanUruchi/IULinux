#!/usr/bin/env bash
set -Eeuo pipefail

trap 'echo "[IULinux] ERROR: ISO build failed at line ${LINENO}" >&2' ERR

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck disable=SC1091
source "${PROJECT_ROOT}/config/build.conf"

ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"
ISO_ROOT="${PROJECT_ROOT}/build/iso-root"

ISO_NAME="IULinux-${IULINUX_VERSION}-${TARGET_ARCH}.iso"
ISO_OUTPUT="${PROJECT_ROOT}/build/${ISO_NAME}"
ISO_VOLUME_ID="IULINUX_DEV"

GRUB_CONFIG_SOURCE="${PROJECT_ROOT}/config/grub.cfg"
GRUB_BACKGROUND_SOURCE="${PROJECT_ROOT}/branding/grub/iulinux-grub-background.png"
GRUB_FONT_SOURCE="/usr/share/grub/unicode.pf2"

[[ -d "${ROOTFS_DIR}" ]] || {
    echo "[IULinux] Rootfs missing." >&2
    exit 1
}

[[ -f "${GRUB_CONFIG_SOURCE}" ]] || {
    echo "[IULinux] GRUB configuration missing." >&2
    exit 1
}

[[ -f "${GRUB_BACKGROUND_SOURCE}" ]] || {
    echo "[IULinux] GRUB background missing." >&2
    exit 1
}

[[ -f "${GRUB_FONT_SOURCE}" ]] || {
    echo "[IULinux] GRUB Unicode font missing." >&2
    exit 1
}

for command in mksquashfs grub-mkrescue xorriso; do
    command -v "${command}" >/dev/null 2>&1 || {
        echo "[IULinux] Missing host tool: ${command}" >&2
        exit 1
    }
done

"${PROJECT_ROOT}/tests/test-rootfs-identity.sh"
"${PROJECT_ROOT}/tests/test-base-system.sh"
"${PROJECT_ROOT}/tests/test-desktop.sh"
"${PROJECT_ROOT}/tests/test-developer.sh"
"${PROJECT_ROOT}/tests/test-containers.sh"
"${PROJECT_ROOT}/tests/test-gpu-base.sh"
"${PROJECT_ROOT}/tests/test-ai-foundation.sh"
"${PROJECT_ROOT}/tests/test-nvidia-policy.sh"
"${PROJECT_ROOT}/tests/test-nvidia-container-policy.sh"
"${PROJECT_ROOT}/tests/test-cuda-policy.sh"
"${PROJECT_ROOT}/tests/test-lean-profile.sh"
"${PROJECT_ROOT}/tests/test-live-system.sh"
"${PROJECT_ROOT}/tests/test-network-policy.sh"
"${PROJECT_ROOT}/tests/test-lean-runtime-policy.sh"
"${PROJECT_ROOT}/tests/test-brave.sh"
"${PROJECT_ROOT}/tests/test-onlyoffice.sh"
"${PROJECT_ROOT}/tests/test-branding.sh"
"${PROJECT_ROOT}/tests/test-sddm-branding.sh"
"${PROJECT_ROOT}/tests/test-grub-branding.sh"
"${PROJECT_ROOT}/tests/test-installer-framework.sh"
"${PROJECT_ROOT}/tests/test-installer-config.sh"

echo
echo "============================================"
echo " IULinux ISO build"
echo "============================================"
echo "Output: ${ISO_OUTPUT}"
echo

sudo rm -rf "${ISO_ROOT}"
rm -f "${ISO_OUTPUT}" "${ISO_OUTPUT}.sha256"

mkdir -p \
    "${ISO_ROOT}/boot/grub" \
    "${ISO_ROOT}/casper" \
    "${ISO_ROOT}/.disk"

KERNEL_SOURCE="$(readlink -f "${ROOTFS_DIR}/boot/vmlinuz")"
INITRD_SOURCE="$(readlink -f "${ROOTFS_DIR}/boot/initrd.img")"

[[ -f "${KERNEL_SOURCE}" ]] || {
    echo "[IULinux] Kernel image missing." >&2
    exit 1
}

[[ -f "${INITRD_SOURCE}" ]] || {
    echo "[IULinux] Initramfs missing." >&2
    exit 1
}

echo "[IULinux] Copying kernel and initramfs..."

sudo cp -L "${KERNEL_SOURCE}" "${ISO_ROOT}/casper/vmlinuz"
sudo cp -L "${INITRD_SOURCE}" "${ISO_ROOT}/casper/initrd"

# Kernel images inside the rootfs may intentionally be root-readable only.
# The ISO copies must be readable by grub-mkrescue and by firmware/bootloaders.
sudo chmod 0644     "${ISO_ROOT}/casper/vmlinuz"     "${ISO_ROOT}/casper/initrd"

sudo chown "$(id -u):$(id -g)"     "${ISO_ROOT}/casper/vmlinuz"     "${ISO_ROOT}/casper/initrd"

echo "[IULinux] Generating package manifest..."

sudo chroot "${ROOTFS_DIR}" \
    dpkg-query \
    -W \
    -f='${Package} ${Version}\n' |
    sort > "${ISO_ROOT}/casper/filesystem.manifest"

sudo du \
    -sx \
    --block-size=1 \
    "${ROOTFS_DIR}" |
    awk '{print $1}' \
    > "${ISO_ROOT}/casper/filesystem.size"

cat > "${ISO_ROOT}/.disk/info" <<INFO
IULinux ${IULINUX_VERSION} ${TARGET_ARCH} Development Live
INFO

echo "[IULinux] Verifying rootfs mount hygiene..."

for pseudo in proc sys dev run; do
    if mountpoint -q "${ROOTFS_DIR}/${pseudo}"; then
        echo "[IULinux] ERROR: ${ROOTFS_DIR}/${pseudo} is still mounted." >&2
        echo "[IULinux] Refusing to package live host pseudo-filesystems." >&2
        exit 1
    fi
done

echo "[IULinux] Rootfs mount hygiene OK."

echo "[IULinux] Building Zstd SquashFS..."

sudo mksquashfs \
    "${ROOTFS_DIR}" \
    "${ISO_ROOT}/casper/filesystem.squashfs" \
    -noappend \
    -comp zstd \
    -Xcompression-level 15 \
    -b 1M \
    -wildcards \
    -e \
        'boot/*' \
        'var/cache/apt/archives/*' \
        'var/lib/apt/lists/*' \
        'var/log/*' \
        'tmp/*' \
        'var/tmp/*'

sudo chown "$(id -u):$(id -g)" \
    "${ISO_ROOT}/casper/filesystem.squashfs"

echo "[IULinux] Installing GRUB branding..."

cp \
    "${GRUB_CONFIG_SOURCE}" \
    "${ISO_ROOT}/boot/grub/grub.cfg"

cp \
    "${GRUB_BACKGROUND_SOURCE}" \
    "${ISO_ROOT}/boot/grub/iulinux-grub-background.png"

mkdir -p "${ISO_ROOT}/boot/grub/fonts"

cp \
    "${GRUB_FONT_SOURCE}" \
    "${ISO_ROOT}/boot/grub/fonts/unicode.pf2"

chmod 0644 \
    "${ISO_ROOT}/boot/grub/grub.cfg" \
    "${ISO_ROOT}/boot/grub/iulinux-grub-background.png" \
    "${ISO_ROOT}/boot/grub/fonts/unicode.pf2"

echo
echo "[IULinux] Generating live-media checksums..."

(
    cd "${ISO_ROOT}"

    find . \
        -type f \
        ! -name 'md5sum.txt' \
        -print0 |
        sort -z |
        xargs -0 md5sum
) > "${ISO_ROOT}/md5sum.txt"

echo
echo "[IULinux] Creating bootable ISO..."

grub-mkrescue \
    -o "${ISO_OUTPUT}" \
    "${ISO_ROOT}" \
    -- \
    -volid "${ISO_VOLUME_ID}"

sha256sum "${ISO_OUTPUT}" |
    tee "${ISO_OUTPUT}.sha256"

echo
echo "============================================"
echo " IULinux ISO COMPLETE"
echo "============================================"

ls -lh "${ISO_OUTPUT}" "${ISO_OUTPUT}.sha256"
