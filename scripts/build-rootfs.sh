#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"

MODE="${1:-}"

STAGES=(
    bootstrap-rootfs.sh
    install-base-system.sh
    install-desktop.sh
    install-developer.sh
    install-containers.sh
    install-brave.sh
    install-onlyoffice.sh
    install-live-system.sh
    install-installer.sh
    apply-overlay.sh
)

show_plan()
{
    echo "============================================"
    echo " IULinux rootfs build pipeline"
    echo "============================================"

    for stage in "${STAGES[@]}"; do
        echo " -> ${stage}"
    done
}

if [[ "${MODE}" == "--plan" ]]; then
    show_plan
    exit 0
fi

if [[ "${MODE}" != "--clean" ]]; then
    cat <<USAGE
Usage:
  $0 --plan
  $0 --clean

--plan   Show the complete rootfs build pipeline.
--clean  Delete build/rootfs and reproduce it from scratch.
USAGE
    exit 2
fi

# Safety: never remove anything except the canonical rootfs.
EXPECTED="${PROJECT_ROOT}/build/rootfs"

[[ "${ROOTFS_DIR}" == "${EXPECTED}" ]] || {
    echo "[FAIL] Unexpected rootfs path: ${ROOTFS_DIR}" >&2
    exit 1
}

echo "============================================"
echo " IULinux CLEAN ROOTFS BUILD"
echo "============================================"
echo "Target: ${ROOTFS_DIR}"
echo

# Never destroy a tree with leaked pseudo-filesystems mounted inside.
for pseudo in dev proc sys run; do
    if mountpoint -q "${ROOTFS_DIR}/${pseudo}" 2>/dev/null; then
        echo "[FAIL] ${ROOTFS_DIR}/${pseudo} is mounted." >&2
        echo "Refusing clean rebuild." >&2
        exit 1
    fi
done

echo "[IULinux] Removing previous rootfs..."
sudo rm -rf "${ROOTFS_DIR}"

run_stage()
{
    local stage="$1"

    echo
    echo "============================================"
    echo " STAGE: ${stage}"
    echo "============================================"

    "${PROJECT_ROOT}/scripts/${stage}"
}

run_stage bootstrap-rootfs.sh
run_stage install-base-system.sh
run_stage install-desktop.sh
run_stage install-developer.sh
run_stage install-containers.sh
run_stage install-brave.sh
run_stage install-onlyoffice.sh
run_stage install-live-system.sh
run_stage install-installer.sh
run_stage apply-overlay.sh

echo
echo "============================================"
echo " IULinux ROOTFS COMPLETE"
echo "============================================"
