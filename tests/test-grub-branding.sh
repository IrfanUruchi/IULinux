#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

GRUB_CONFIG="${PROJECT_ROOT}/config/grub.cfg"
GRUB_BACKGROUND="${PROJECT_ROOT}/branding/grub/iulinux-grub-background.png"
BUILD_SCRIPT="${PROJECT_ROOT}/scripts/build-iso.sh"

fail()
{
    echo "[FAIL] $*" >&2
    exit 1
}

# ------------------------------------------------------------
# Branding assets
# ------------------------------------------------------------

[[ -f "${GRUB_BACKGROUND}" ]] ||
    fail "IULinux GRUB background missing"

[[ -s "${GRUB_BACKGROUND}" ]] ||
    fail "IULinux GRUB background is empty"

file "${GRUB_BACKGROUND}" |
    grep -q 'PNG image data' ||
    fail "IULinux GRUB background is not PNG"

# ------------------------------------------------------------
# GRUB configuration
# ------------------------------------------------------------

[[ -f "${GRUB_CONFIG}" ]] ||
    fail "IULinux GRUB configuration missing"

[[ -s "${GRUB_CONFIG}" ]] ||
    fail "IULinux GRUB configuration is empty"

grep -qx 'insmod all_video' "${GRUB_CONFIG}" ||
    fail "GRUB video module policy missing"

grep -qx 'insmod gfxterm' "${GRUB_CONFIG}" ||
    fail "GRUB gfxterm module policy missing"

grep -qx 'insmod png' "${GRUB_CONFIG}" ||
    fail "GRUB PNG module policy missing"

grep -qx 'loadfont /boot/grub/fonts/unicode.pf2' "${GRUB_CONFIG}" ||
    fail "GRUB Unicode font policy missing"

grep -qF 'GRUB_FONT_SOURCE="/usr/share/grub/unicode.pf2"' "${BUILD_SCRIPT}" ||
    fail "GRUB Unicode font is not wired into ISO builder"

grep -qx \
    'background_image /boot/grub/iulinux-grub-background.png' \
    "${GRUB_CONFIG}" ||
    fail "IULinux GRUB background policy missing"

# ------------------------------------------------------------
# Boot entries
# ------------------------------------------------------------

grep -qF 'menuentry "Start IULinux"' "${GRUB_CONFIG}" ||
    fail "Normal IULinux boot entry missing"

grep -qF \
    'linux /casper/vmlinuz boot=casper username=iulinux hostname=iulinux-live noprompt ---' \
    "${GRUB_CONFIG}" ||
    fail "Normal Casper boot policy changed"

grep -qF 'menuentry "Start IULinux (safe graphics)"' "${GRUB_CONFIG}" ||
    fail "Safe-graphics boot entry missing"

grep -qF \
    'linux /casper/vmlinuz boot=casper username=iulinux hostname=iulinux-live noprompt nomodeset ---' \
    "${GRUB_CONFIG}" ||
    fail "Safe-graphics Casper policy changed"

grep -qF 'initrd /casper/initrd' "${GRUB_CONFIG}" ||
    fail "GRUB initramfs policy missing"

# ------------------------------------------------------------
# Build integration
# ------------------------------------------------------------

grep -qF \
    'GRUB_CONFIG_SOURCE="${PROJECT_ROOT}/config/grub.cfg"' \
    "${BUILD_SCRIPT}" ||
    fail "GRUB config is not wired into ISO builder"

grep -qF \
    'GRUB_BACKGROUND_SOURCE="${PROJECT_ROOT}/branding/grub/iulinux-grub-background.png"' \
    "${BUILD_SCRIPT}" ||
    fail "GRUB background is not wired into ISO builder"

echo "[PASS] IULinux GRUB branding"
