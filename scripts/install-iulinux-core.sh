#!/usr/bin/env bash
set -Eeuo pipefail

trap 'echo "[IULinux] ERROR: core installation failed at line ${LINENO}" >&2' ERR

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"
CHROOT_RUN="${PROJECT_ROOT}/scripts/chroot-run.sh"

SYSTEM_CONTROL="${PROJECT_ROOT}/packaging/iulinux-system/DEBIAN/control"
PUBLIC_KEY="${PROJECT_ROOT}/packaging/iulinux-archive-keyring/rootfs/usr/share/keyrings/iulinux-archive-keyring.gpg"

REPOSITORY_URI="https://irfanuruchi.github.io/iulinux-archive/"
SUITE="resolute-alpha"

BOOTSTRAP_KEY="/usr/share/keyrings/iulinux-bootstrap-archive-keyring.gpg"
BOOTSTRAP_SOURCE="/etc/apt/sources.list.d/iulinux-bootstrap.sources"
PERMANENT_KEY="/usr/share/keyrings/iulinux-archive-keyring.gpg"
PERMANENT_SOURCE="/etc/apt/sources.list.d/iulinux.sources"

[[ -d "${ROOTFS_DIR}" ]] || {
    echo "[FAIL] Missing rootfs." >&2
    exit 1
}

[[ -f "${SYSTEM_CONTROL}" ]] || {
    echo "[FAIL] Missing iulinux-system control file." >&2
    exit 1
}

[[ -f "${PUBLIC_KEY}" ]] || {
    echo "[FAIL] Missing IULinux archive public key." >&2
    exit 1
}

SYSTEM_VERSION="$(
    awk -F': *' '$1 == "Version" {print $2; exit}' "${SYSTEM_CONTROL}"
)"

[[ -n "${SYSTEM_VERSION}" ]] || {
    echo "[FAIL] Unable to determine iulinux-system version." >&2
    exit 1
}

sudo -v

cleanup()
{
    sudo rm -f \
        "${ROOTFS_DIR}${BOOTSTRAP_SOURCE}" \
        "${ROOTFS_DIR}${BOOTSTRAP_KEY}"
}

trap cleanup EXIT

echo "============================================"
echo " IULinux core installation"
echo "============================================"
echo "System package: iulinux-system=${SYSTEM_VERSION}"
echo "Repository:     ${REPOSITORY_URI}"
echo

echo "[IULinux] Installing temporary archive trust bootstrap..."

sudo install \
    -Dm644 \
    "${PUBLIC_KEY}" \
    "${ROOTFS_DIR}${BOOTSTRAP_KEY}"

sudo mkdir -p "${ROOTFS_DIR}/etc/apt/sources.list.d"

sudo tee "${ROOTFS_DIR}${BOOTSTRAP_SOURCE}" >/dev/null <<EOF_SOURCE
Types: deb
URIs: ${REPOSITORY_URI}
Suites: ${SUITE}
Components: main
Architectures: amd64
Signed-By: ${BOOTSTRAP_KEY}
EOF_SOURCE

echo "[IULinux] Authenticating public IULinux archive..."

"${CHROOT_RUN}" \
    /usr/bin/env \
    DEBIAN_FRONTEND=noninteractive \
    apt-get update

echo
echo "[IULinux] Installing published IULinux core..."

"${CHROOT_RUN}" \
    /usr/bin/env \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install \
        -y \
        --no-install-recommends \
        "iulinux-system=${SYSTEM_VERSION}"

echo
echo "[IULinux] Removing temporary bootstrap trust..."

cleanup
trap - EXIT

echo
echo "[IULinux] Validating permanent repository configuration..."

[[ -f "${ROOTFS_DIR}${PERMANENT_KEY}" ]] || {
    echo "[FAIL] Permanent archive key was not installed." >&2
    exit 1
}

[[ -f "${ROOTFS_DIR}${PERMANENT_SOURCE}" ]] || {
    echo "[FAIL] Permanent repository source was not installed." >&2
    exit 1
}

"${CHROOT_RUN}" apt-get update

echo
echo "[IULinux] Installed core packages:"

"${CHROOT_RUN}" \
    dpkg-query -W \
    -f='${Package} ${Version}\n' \
    iulinux-archive-keyring \
    iulinux-release \
    iulinux-repository \
    iulinux-system \
    iulinux-update

echo
echo "============================================"
echo " IULinux core COMPLETE"
echo "============================================"
