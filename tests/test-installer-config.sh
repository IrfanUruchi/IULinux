#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"

fail()
{
    echo "[FAIL] $*" >&2
    exit 1
}

SETTINGS="${ROOTFS_DIR}/etc/calamares/settings.conf"
BRANDING="${ROOTFS_DIR}/etc/calamares/branding/iulinux/branding.desc"
BOOTLOADER="${ROOTFS_DIR}/etc/calamares/modules/bootloader.conf"
PARTITION="${ROOTFS_DIR}/etc/calamares/modules/partition.conf"
CLEANUP="${ROOTFS_DIR}/etc/calamares/modules/shellprocess_target_cleanup.conf"
DESKTOP="${ROOTFS_DIR}/usr/share/applications/iulinux-installer.desktop"
LAUNCHER="${ROOTFS_DIR}/usr/bin/iulinux-installer"

for file in \
    "${SETTINGS}" \
    "${BRANDING}" \
    "${BOOTLOADER}" \
    "${PARTITION}" \
    "${CLEANUP}" \
    "${DESKTOP}" \
    "${LAUNCHER}"
do
    [[ -s "${file}" ]] ||
        fail "Installer configuration missing: ${file}"
done

for package in \
    calamares \
    squashfs-tools \
    grub-pc-bin \
    grub-efi-amd64-bin \
    efibootmgr
do
    status="$(
        dpkg-query \
            --admindir="${ROOTFS_DIR}/var/lib/dpkg" \
            -W \
            -f='${db:Status-Abbrev}' \
            "${package}" 2>/dev/null || true
    )"

    [[ "${status}" == "ii " ]] ||
        fail "Installer runtime package missing: ${package}"
done

grep -qx 'branding: iulinux' "${SETTINGS}" ||
    fail "IULinux Calamares branding not selected"

grep -q 'shellprocess@target_cleanup' "${SETTINGS}" ||
    fail "Target cleanup job missing"

if grep -qE '(^|[[:space:]-])removeuser([[:space:]]|$)' "${SETTINGS}"; then
    fail "removeuser must not be used for Casper-created runtime user"
fi

grep -qx 'efiBootloaderId: "iulinux"' "${BOOTLOADER}" ||
    fail "Installed EFI bootloader ID is not IULinux"

grep -qx 'defaultFileSystemType: "ext4"' "${PARTITION}" ||
    fail "Installer-0B must default to ext4"

grep -qx 'enableLuksAutomatedPartitioning: false' "${PARTITION}" ||
    fail "Installer-0B encryption must remain disabled"

grep -qF \
    'rm -f /etc/sddm.conf.d/iulinux-live.conf' \
    "${CLEANUP}" ||
    fail "Live SDDM cleanup missing"

if grep -q 'autoremove' "${CLEANUP}"; then
    fail "Installer cleanup must not autoremove packages"
fi

grep -qx 'Name=Install IULinux' "${DESKTOP}" ||
    fail "Install IULinux desktop entry missing"

grep -qx 'Icon=iulinux' "${DESKTOP}" ||
    fail "Installer does not use IULinux icon"

grep -qx 'Exec=sudo /usr/bin/iulinux-installer' "${DESKTOP}" ||
    fail "Installer desktop entry does not invoke IULinux launcher"

[[ -x "${LAUNCHER}" ]] ||
    fail "IULinux installer launcher is not executable"

grep -qF 'exec /usr/bin/calamares -D8' "${LAUNCHER}" ||
    fail "IULinux installer launcher does not start Calamares"

echo "[PASS] IULinux Calamares configuration"
