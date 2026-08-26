#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${PROJECT_ROOT}/build/rootfs"
PROFILE_OVERLAY="${PROJECT_ROOT}/profiles/ai/overlay"

echo "============================================"
echo " IULinux OPTIONAL AI PROFILE"
echo "============================================"

"${PROJECT_ROOT}/scripts/install-ai-foundation.sh"
"${PROJECT_ROOT}/scripts/install-ai-runtime.sh"

echo "[IULinux] Applying optional AI profile overlay..."
sudo rsync -aHAX --numeric-ids     "${PROFILE_OVERLAY}/"     "${ROOTFS}/"

"${PROJECT_ROOT}/tests/test-ai-foundation.sh"
"${PROJECT_ROOT}/tests/test-ai-runtime.sh"

echo
echo "[PASS] Optional IULinux AI profile installed"
