#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "============================================"
echo " IULinux OPTIONAL AI PROFILE"
echo "============================================"

"${PROJECT_ROOT}/scripts/install-ai-foundation.sh"
"${PROJECT_ROOT}/scripts/install-ai-runtime.sh"
"${PROJECT_ROOT}/scripts/apply-overlay.sh"

"${PROJECT_ROOT}/tests/test-ai-foundation.sh"
"${PROJECT_ROOT}/tests/test-ai-runtime.sh"

echo
echo "[PASS] Optional IULinux AI profile installed"
