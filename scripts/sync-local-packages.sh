#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"
CHROOT_RUN="${PROJECT_ROOT}/scripts/chroot-run.sh"

REPOSITORY_URI="${IULINUX_REPOSITORY_URI:-https://irfanuruchi.github.io/iulinux-archive/}"

STAGE_REL="/tmp/iulinux-local-sync"
STAGE_HOST="${ROOTFS_DIR}${STAGE_REL}"

fail()
{
    echo "[FAIL] $*" >&2
    exit 1
}

[[ -d "${ROOTFS_DIR}" ]] ||
    fail "Rootfs missing"

[[ -x "${CHROOT_RUN}" ]] ||
    fail "chroot-run helper missing"

[[ "${REPOSITORY_URI}" == https://* ]] ||
    fail "Repository URI must use HTTPS"

sudo -v

cleanup()
{
    sudo rm -rf "${STAGE_HOST}"
}

trap cleanup EXIT

shopt -s nullglob

controls=(
    "${PROJECT_ROOT}"/packaging/*/DEBIAN/control
)

(( ${#controls[@]} > 0 )) ||
    fail "No IULinux package controls found"

debs=()

echo "============================================"
echo " IULinux local package sync"
echo "============================================"
echo "Rootfs: ${ROOTFS_DIR}"
echo

for control in "${controls[@]}"; do
    package="$(
        awk -F': *' '$1 == "Package" {print $2; exit}' \
            "${control}"
    )"

    version="$(
        awk -F': *' '$1 == "Version" {print $2; exit}' \
            "${control}"
    )"

    arch="$(
        awk -F': *' '$1 == "Architecture" {print $2; exit}' \
            "${control}"
    )"

    [[ -n "${package}" ]] ||
        fail "Missing Package field: ${control}"

    [[ -n "${version}" ]] ||
        fail "Missing Version field: ${control}"

    [[ -n "${arch}" ]] ||
        fail "Missing Architecture field: ${control}"

    echo "[IULinux] Building ${package}=${version}"

    if [[ "${package}" == "iulinux-repository" ]]; then
        "${PROJECT_ROOT}/scripts/build-repository-package.sh" \
            "${REPOSITORY_URI}"
    else
        "${PROJECT_ROOT}/scripts/build-deb.sh" \
            "${package}"
    fi

    deb="${PROJECT_ROOT}/build/packages/${package}_${version}_${arch}.deb"

    [[ -f "${deb}" ]] ||
        fail "Expected package was not built: ${deb}"

    debs+=("${deb}")
done

echo
echo "[IULinux] Staging local packages..."

sudo rm -rf "${STAGE_HOST}"
sudo install -d -m0755 "${STAGE_HOST}"

guest_debs=()

for deb in "${debs[@]}"; do
    name="$(basename "${deb}")"

    sudo install \
        -m0644 \
        "${deb}" \
        "${STAGE_HOST}/${name}"

    guest_debs+=("${STAGE_REL}/${name}")
done

echo
echo "[IULinux] Unpacking local package set..."

"${CHROOT_RUN}" \
    dpkg --unpack \
    "${guest_debs[@]}"

echo
echo "[IULinux] Refreshing package indexes..."

"${CHROOT_RUN}" \
    /usr/bin/env \
    DEBIAN_FRONTEND=noninteractive \
    apt-get update

echo
echo "[IULinux] Resolving and configuring dependencies..."

"${CHROOT_RUN}" \
    /usr/bin/env \
    DEBIAN_FRONTEND=noninteractive \
    apt-get \
        -y \
        --no-install-recommends \
        --no-remove \
        --fix-broken install

echo
echo "[IULinux] Verifying package consistency..."

"${PROJECT_ROOT}/tests/test-package-consistency.sh"

cleanup
trap - EXIT

echo
echo "============================================"
echo " IULinux local package sync COMPLETE"
echo "============================================"
