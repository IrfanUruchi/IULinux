#!/usr/bin/env bash
set -Eeuo pipefail

trap 'echo "[IULinux] ERROR: bootstrap failed at line ${LINENO}" >&2' ERR

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_FILE="${PROJECT_ROOT}/config/build.conf"
ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"

if [[ ! -f "${CONFIG_FILE}" ]]; then
    echo "[IULinux] Missing configuration: ${CONFIG_FILE}" >&2
    exit 1
fi

# shellcheck disable=SC1090
source "${CONFIG_FILE}"

for command in debootstrap sudo; do
    if ! command -v "${command}" >/dev/null 2>&1; then
        echo "[IULinux] Required command not found: ${command}" >&2
        exit 1
    fi
done

CLEAN=0

case "${1:-}" in
    "")
        ;;
    --clean)
        CLEAN=1
        ;;
    *)
        echo "Usage: $0 [--clean]" >&2
        exit 2
        ;;
esac

echo "============================================"
echo " IULinux root filesystem bootstrap"
echo "============================================"
echo "Project:      ${PROJECT_ROOT}"
echo "Base:         Ubuntu ${UBUNTU_SUITE}"
echo "Architecture: ${TARGET_ARCH}"
echo "Mirror:       ${UBUNTU_MIRROR}"
echo "Rootfs:       ${ROOTFS_DIR}"
echo

# Validate sudo before starting a potentially long build.
sudo -v

if [[ -d "${ROOTFS_DIR}" ]] &&
   [[ -n "$(sudo find "${ROOTFS_DIR}" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then

    if [[ "${CLEAN}" -eq 1 ]]; then
        if [[ "${ROOTFS_DIR}" != "${PROJECT_ROOT}/build/rootfs" ]]; then
            echo "[IULinux] Refusing unsafe cleanup path: ${ROOTFS_DIR}" >&2
            exit 1
        fi

        echo "[IULinux] Removing previous rootfs..."
        sudo rm -rf -- "${ROOTFS_DIR}"
    else
        echo "[IULinux] Existing rootfs detected."
        echo "[IULinux] Re-run with --clean to rebuild it:"
        echo "           ./scripts/bootstrap-rootfs.sh --clean"
        exit 1
    fi
fi

sudo mkdir -p "${ROOTFS_DIR}"

echo
echo "[IULinux] Bootstrapping Ubuntu ${UBUNTU_SUITE}..."

sudo debootstrap \
    --arch="${TARGET_ARCH}" \
    --variant=minbase \
    --components=main \
    "${UBUNTU_SUITE}" \
    "${ROOTFS_DIR}" \
    "${UBUNTU_MIRROR}"

echo
echo "[IULinux] Configuring Ubuntu repositories..."

sudo mkdir -p "${ROOTFS_DIR}/etc/apt/sources.list.d"

sudo tee "${ROOTFS_DIR}/etc/apt/sources.list.d/ubuntu.sources" >/dev/null <<SOURCES
Types: deb
URIs: ${UBUNTU_MIRROR}
Suites: ${UBUNTU_SUITE} ${UBUNTU_SUITE}-updates ${UBUNTU_SUITE}-backports
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg

Types: deb
URIs: ${UBUNTU_SECURITY_MIRROR}
Suites: ${UBUNTU_SUITE}-security
Components: main restricted universe multiverse
Signed-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg
SOURCES

# Remove the legacy source created by debootstrap so that ubuntu.sources
# remains the single authoritative repository configuration.
sudo rm -f "${ROOTFS_DIR}/etc/apt/sources.list"

echo "iulinux" | sudo tee "${ROOTFS_DIR}/etc/hostname" >/dev/null

echo
echo "[IULinux] Writing build metadata..."

cat > "${PROJECT_ROOT}/build/rootfs-build-info.txt" <<INFO
IULinux channel: ${IULINUX_CHANNEL}
Ubuntu suite: ${UBUNTU_SUITE}
Architecture: ${TARGET_ARCH}
Mirror: ${UBUNTU_MIRROR}
Debootstrap: $(debootstrap --version 2>&1 | head -n1)
INFO

echo
echo "============================================"
echo " IULinux rootfs bootstrap COMPLETE"
echo "============================================"
echo
echo "Base OS:"
sudo chroot "${ROOTFS_DIR}" /bin/cat /etc/os-release

echo
echo "Architecture:"
sudo chroot "${ROOTFS_DIR}" /usr/bin/dpkg --print-architecture

echo
echo "Rootfs size:"
sudo du -sh "${ROOTFS_DIR}"

echo
echo "[IULinux] Success."
