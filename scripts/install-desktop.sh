#!/usr/bin/env bash
set -Eeuo pipefail

trap 'echo "[IULinux] ERROR: desktop installation failed at line ${LINENO}" >&2' ERR

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"
PACKAGE_LIST="${PROJECT_ROOT}/packages/desktop.list"
CHROOT_RUN="${PROJECT_ROOT}/scripts/chroot-run.sh"

if [[ ! -d "${ROOTFS_DIR}" ]]; then
    echo "[IULinux] Missing rootfs: ${ROOTFS_DIR}" >&2
    exit 1
fi

if [[ ! -f "${PACKAGE_LIST}" ]]; then
    echo "[IULinux] Missing desktop package manifest: ${PACKAGE_LIST}" >&2
    exit 1
fi

mapfile -t PACKAGES < <(
    sed \
        -e 's/[[:space:]]*#.*$//' \
        -e '/^[[:space:]]*$/d' \
        "${PACKAGE_LIST}"
)

if [[ "${#PACKAGES[@]}" -eq 0 ]]; then
    echo "[IULinux] Desktop package manifest is empty." >&2
    exit 1
fi

sudo -v

echo "============================================"
echo " IULinux KDE Plasma installation"
echo "============================================"
echo "Packages: ${#PACKAGES[@]}"
echo

echo "[IULinux] Updating package metadata..."

"${CHROOT_RUN}" \
    /usr/bin/env \
    DEBIAN_FRONTEND=noninteractive \
    apt-get update

echo
echo "[IULinux] Validating package availability..."

for package in "${PACKAGES[@]}"; do
    candidate="$(
        "${CHROOT_RUN}" \
            apt-cache policy "${package}" |
            awk '/Candidate:/ {print $2; exit}'
    )"

    if [[ -z "${candidate}" || "${candidate}" == "(none)" ]]; then
        echo "[IULinux] Package unavailable: ${package}" >&2
        exit 1
    fi

    printf '  %-30s %s\n' "${package}" "${candidate}"
done

# Do not start services while constructing the offline filesystem.
sudo tee "${ROOTFS_DIR}/usr/sbin/policy-rc.d" >/dev/null <<'POLICY'
#!/bin/sh
exit 101
POLICY

sudo chmod 755 "${ROOTFS_DIR}/usr/sbin/policy-rc.d"

cleanup()
{
    sudo rm -f "${ROOTFS_DIR}/usr/sbin/policy-rc.d"
}

trap cleanup EXIT

echo
echo "[IULinux] Installing KDE Plasma desktop..."

"${CHROOT_RUN}" \
    /usr/bin/env \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install \
        -y \
        --no-install-recommends \
        "${PACKAGES[@]}"

echo
echo "[IULinux] Enabling graphical boot target..."

sudo ln -sfn \
    /usr/lib/systemd/system/graphical.target \
    "${ROOTFS_DIR}/etc/systemd/system/default.target"

echo "[IULinux] Enabling SDDM..."

"${CHROOT_RUN}" \
    systemctl enable sddm.service

echo
echo "[IULinux] Cleaning package cache..."

"${CHROOT_RUN}" apt-get clean

cleanup
trap - EXIT

# base-files or related packages can modify distro identity.
echo
echo "[IULinux] Re-applying distro overlay..."

"${PROJECT_ROOT}/scripts/apply-overlay.sh"

"${PROJECT_ROOT}/tests/test-rootfs-identity.sh"
"${PROJECT_ROOT}/tests/test-base-system.sh"

echo
echo "============================================"
echo " IULinux KDE Plasma COMPLETE"
echo "============================================"

echo
echo "Rootfs size:"
sudo du -sh "${ROOTFS_DIR}"
