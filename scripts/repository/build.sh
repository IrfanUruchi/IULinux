#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

SUITE="${1:-resolute-alpha}"
CHANNEL="${2:-alpha}"

PACKAGES_DIR="${PROJECT_ROOT}/build/packages"
REPO_ROOT="${PROJECT_ROOT}/build/apt-repo"

shopt -s nullglob
debs=("${PACKAGES_DIR}"/*.deb)

(( ${#debs[@]} > 0 )) || {
    echo "[FAIL] No .deb packages found in ${PACKAGES_DIR}"
    exit 1
}

rm -rf "${REPO_ROOT}"

mkdir -p \
    "${REPO_ROOT}/pool/main" \
    "${REPO_ROOT}/dists/${SUITE}/main/binary-amd64"

cp "${debs[@]}" "${REPO_ROOT}/pool/main/"

cd "${REPO_ROOT}"

apt-ftparchive packages pool/main \
    > "dists/${SUITE}/main/binary-amd64/Packages"

gzip -9fk "dists/${SUITE}/main/binary-amd64/Packages"

apt-ftparchive \
    -o APT::FTPArchive::Release::Origin="IULinux" \
    -o APT::FTPArchive::Release::Label="IULinux" \
    -o APT::FTPArchive::Release::Suite="${CHANNEL}" \
    -o APT::FTPArchive::Release::Codename="${SUITE}" \
    -o APT::FTPArchive::Release::Architectures="amd64" \
    -o APT::FTPArchive::Release::Components="main" \
    release "dists/${SUITE}" \
    > /tmp/iulinux-release.$$

mv /tmp/iulinux-release.$$ "dists/${SUITE}/Release"

echo "[PASS] Repository built"
echo "Suite:    ${SUITE}"
echo "Channel:  ${CHANNEL}"
echo "Packages: ${#debs[@]}"
echo "Path:     ${REPO_ROOT}"
