#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

SUITE="${1:-resolute-alpha}"
KEY="${2:-}"

[[ -n "${KEY}" ]] || {
    echo "Usage: $0 [suite] <signing-key-fingerprint>"
    exit 2
}

REPO_ROOT="${PROJECT_ROOT}/build/apt-repo"
DIST_ROOT="${REPO_ROOT}/dists/${SUITE}"
RELEASE="${DIST_ROOT}/Release"

[[ -f "${RELEASE}" ]] || {
    echo "[FAIL] Missing Release file: ${RELEASE}"
    exit 1
}

rm -f \
    "${DIST_ROOT}/InRelease" \
    "${DIST_ROOT}/Release.gpg"

gpg \
    --batch \
    --yes \
    --local-user "${KEY}" \
    --clearsign \
    --output "${DIST_ROOT}/InRelease" \
    "${RELEASE}"

gpg \
    --batch \
    --yes \
    --local-user "${KEY}" \
    --armor \
    --detach-sign \
    --output "${DIST_ROOT}/Release.gpg" \
    "${RELEASE}"

[[ -s "${DIST_ROOT}/InRelease" ]] ||
    {
        echo "[FAIL] InRelease was not created"
        exit 1
    }

[[ -s "${DIST_ROOT}/Release.gpg" ]] ||
    {
        echo "[FAIL] Release.gpg was not created"
        exit 1
    }

echo "[PASS] Repository signed"
echo "Suite: ${SUITE}"
echo "Key:   ${KEY}"
