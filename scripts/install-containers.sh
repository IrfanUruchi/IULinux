#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${PROJECT_ROOT}/build/rootfs"
PACKAGE_LIST="${PROJECT_ROOT}/packages/containers.list"

[[ -d "${ROOTFS}" ]] || {
    echo "[FAIL] Missing rootfs: ${ROOTFS}" >&2
    exit 1
}

CODENAME="$(
    awk -F= '
        /^UBUNTU_CODENAME=/ {
            gsub(/"/, "", $2)
            print $2
            exit
        }
    ' "${ROOTFS}/etc/os-release"
)"

[[ -n "${CODENAME}" ]] || {
    echo "[FAIL] Cannot determine Ubuntu base codename." >&2
    exit 1
}

ARCH="$(sudo chroot "${ROOTFS}" dpkg --print-architecture)"

echo "============================================"
echo " IULinux container workstation"
echo "============================================"
echo "Base: Ubuntu ${CODENAME}"
echo "Arch: ${ARCH}"

echo
echo "[IULinux] Configuring Docker official repository..."

TMP_KEY="$(mktemp)"
trap 'rm -f "${TMP_KEY}"' EXIT

curl -fsSL \
    https://download.docker.com/linux/ubuntu/gpg \
    -o "${TMP_KEY}"

sudo install -d -m 0755 "${ROOTFS}/etc/apt/keyrings"

sudo install -m 0644 \
    "${TMP_KEY}" \
    "${ROOTFS}/etc/apt/keyrings/docker.asc"

sudo tee "${ROOTFS}/etc/apt/sources.list.d/docker.sources" >/dev/null <<REPO
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${CODENAME}
Components: stable
Architectures: ${ARCH}
Signed-By: /etc/apt/keyrings/docker.asc
REPO

echo "[IULinux] Removing conflicting container packages if present..."

CONFLICTS=(
    docker.io
    docker-compose
    docker-compose-v2
    docker-doc
    docker-buildx
    podman-docker
    containerd
    runc
)

INSTALLED_CONFLICTS=()

for pkg in "${CONFLICTS[@]}"; do
    if sudo chroot "${ROOTFS}" \
        dpkg-query -W -f='${db:Status-Abbrev}' "${pkg}" \
        2>/dev/null | grep -q '^ii '; then
        INSTALLED_CONFLICTS+=("${pkg}")
    fi
done

if ((${#INSTALLED_CONFLICTS[@]})); then
    "${PROJECT_ROOT}/scripts/chroot-run.sh" \
        env DEBIAN_FRONTEND=noninteractive \
        apt-get remove -y "${INSTALLED_CONFLICTS[@]}"
fi

"${PROJECT_ROOT}/scripts/chroot-run.sh" apt-get update

mapfile -t PACKAGES < <(
    sed \
        -e 's/#.*$//' \
        -e '/^[[:space:]]*$/d' \
        "${PACKAGE_LIST}"
)

"${PROJECT_ROOT}/scripts/chroot-run.sh" \
    env DEBIAN_FRONTEND=noninteractive \
    apt-get install -y --no-install-recommends "${PACKAGES[@]}"

echo
echo "[IULinux] Container workstation installed."
