#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"

MODE="${1:-}"

case "${MODE}" in
    --plan|--clean)
        CORE_STAGE="install-iulinux-core.sh"
        CORE_SOURCE="published signed archive"
        ;;
    --plan-local|--clean-local)
        CORE_STAGE="sync-local-packages.sh"
        CORE_SOURCE="local package sources"
        ;;
    *)
        cat <<USAGE
Usage:
  $0 --plan
  $0 --plan-local
  $0 --clean
  $0 --clean-local

--plan         Show the published-package rootfs pipeline.
--plan-local   Show the local-development rootfs pipeline.
--clean        Rebuild using the signed published IULinux archive.
--clean-local  Rebuild using the current local IULinux package sources.
USAGE
        exit 2
        ;;
esac

STAGES=(
    bootstrap-rootfs.sh
    install-base-system.sh
    "${CORE_STAGE}"
    install-desktop.sh
    install-developer.sh
    install-containers.sh
    install-gpu-base.sh
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
    echo "Core source: ${CORE_SOURCE}"
    echo

    for stage in "${STAGES[@]}"; do
        echo " -> ${stage}"
    done
}

if [[ "${MODE}" == "--plan" ||
      "${MODE}" == "--plan-local" ]]; then
    show_plan
    exit 0
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

for stage in "${STAGES[@]}"; do
    run_stage "${stage}"
done

echo
echo "============================================"
echo " IULinux ROOTFS COMPLETE"
echo "============================================"
