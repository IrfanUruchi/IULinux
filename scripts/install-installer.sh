#!/usr/bin/env bash
set -Eeuo pipefail

trap 'echo "[IULinux] ERROR: Installer framework installation failed at line ${LINENO}" >&2' ERR

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"
CHROOT_RUN="${PROJECT_ROOT}/scripts/chroot-run.sh"
PACKAGE_LIST="${PROJECT_ROOT}/packages/installer.list"

[[ -d "${ROOTFS_DIR}" ]] || {
    echo "[IULinux] Rootfs missing." >&2
    exit 1
}

[[ -f "${PACKAGE_LIST}" ]] || {
    echo "[IULinux] Installer package list missing." >&2
    exit 1
}

mapfile -t PACKAGES < <(
    sed \
        -e 's/#.*//' \
        -e '/^[[:space:]]*$/d' \
        "${PACKAGE_LIST}"
)

((${#PACKAGES[@]} > 0)) || {
    echo "[IULinux] Installer package list is empty." >&2
    exit 1
}

sudo -v

echo "============================================"
echo " IULinux installer framework"
echo "============================================"
echo "Packages: ${#PACKAGES[@]}"
echo

echo "[IULinux] Updating package metadata..."
"${CHROOT_RUN}" apt-get update

echo
echo "[IULinux] Validating package availability..."

for package in "${PACKAGES[@]}"; do
    candidate="$(
        "${CHROOT_RUN}" apt-cache policy "${package}" |
            awk '/Candidate:/ {print $2; exit}'
    )"

    if [[ -z "${candidate}" || "${candidate}" == "(none)" ]]; then
        echo "[IULinux] No candidate for ${package}" >&2
        exit 1
    fi

    printf '  %-28s %s\n' "${package}" "${candidate}"
done

echo
echo "[IULinux] Installing Calamares framework..."

"${CHROOT_RUN}" \
    /usr/bin/env \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install \
        -y \
        --no-install-recommends \
        "${PACKAGES[@]}"

echo
echo "[IULinux] Removing generic Calamares launcher..."

"${CHROOT_RUN}" rm -f     /usr/share/applications/calamares.desktop

echo
echo "[IULinux] Cleaning package cache..."
"${CHROOT_RUN}" apt-get clean

echo
echo "[IULinux] Re-applying distro overlay..."
"${PROJECT_ROOT}/scripts/apply-overlay.sh"

echo
echo "============================================"
echo " IULinux installer framework COMPLETE"
echo "============================================"

"${CHROOT_RUN}" \
    dpkg-query \
    -W \
    -f='${Package}\t${Version}\n' \
    calamares
