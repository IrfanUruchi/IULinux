#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${PROJECT_ROOT}/build/rootfs"

fail()
{
    echo "[FAIL] IULinux container workstation: $*"
    exit 1
}

PACKAGES=(
    docker-ce
    docker-ce-cli
    containerd.io
    docker-buildx-plugin
    docker-compose-plugin
)

for pkg in "${PACKAGES[@]}"; do
    status="$(
        sudo chroot "${ROOTFS}" \
            dpkg-query -W -f='${db:Status-Abbrev}' "${pkg}" \
            2>/dev/null || true
    )"

    [[ "${status}" == "ii " ]] ||
        fail "${pkg} not installed"
done

for bin in docker dockerd containerd ctr; do
    [[ -x "${ROOTFS}/usr/bin/${bin}" ]] ||
        fail "${bin} missing"
done

[[ -s "${ROOTFS}/etc/apt/keyrings/docker.asc" ]] ||
    fail "Docker signing key missing"

grep -q \
    'URIs: https://download.docker.com/linux/ubuntu' \
    "${ROOTFS}/etc/apt/sources.list.d/docker.sources" ||
    fail "Docker repository missing"

grep -q '^Suites: resolute$' \
    "${ROOTFS}/etc/apt/sources.list.d/docker.sources" ||
    fail "Docker repository is not using Resolute"

[[ -f "${ROOTFS}/usr/lib/systemd/system/docker.service" ]] ||
    fail "docker.service missing"

[[ -f "${ROOTFS}/usr/lib/systemd/system/containerd.service" ]] ||
    fail "containerd.service missing"

"${PROJECT_ROOT}/scripts/chroot-run.sh" \
    docker compose version >/dev/null ||
    fail "Docker Compose plugin"

"${PROJECT_ROOT}/scripts/chroot-run.sh" \
    docker buildx version >/dev/null ||
    fail "Docker Buildx plugin"

echo "[PASS] IULinux container workstation"
