#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${PROJECT_ROOT}/build/rootfs"
ISO="${PROJECT_ROOT}/build/IULinux-0.1-dev-amd64.iso"
SHA="${ISO}.sha256"

PASS=0
FAIL=0

pass()
{
    echo "[PASS] $*"
    PASS=$((PASS + 1))
}

fail()
{
    echo "[FAIL] $*" >&2
    FAIL=$((FAIL + 1))
}

section()
{
    echo
    echo "============================================"
    echo " $*"
    echo "============================================"
}

section "IULinux release gate"

echo "Project: ${PROJECT_ROOT}"
echo "Rootfs:  ${ROOTFS}"
echo "ISO:     ${ISO}"


section "SOURCE TREE"

if [[ -z "$(git -C "${PROJECT_ROOT}" status --porcelain)" ]]; then
    pass "Git working tree clean"
else
    fail "Git working tree contains uncommitted changes"
    git -C "${PROJECT_ROOT}" status --short
fi

COMMIT="$(git -C "${PROJECT_ROOT}" rev-parse HEAD)"
echo "Commit: ${COMMIT}"


section "ROOTFS"

if [[ -d "${ROOTFS}" ]]; then
    pass "Rootfs exists"
else
    fail "Rootfs missing"
fi

for m in dev proc sys run; do
    if mountpoint -q "${ROOTFS}/${m}" 2>/dev/null; then
        fail "Rootfs mount leaked: ${m}"
    else
        pass "Rootfs ${m} mount clean"
    fi
done


section "IDENTITY"

if grep -qx 'ID=iulinux' "${ROOTFS}/usr/lib/os-release"; then
    pass "IULinux operating-system identity"
else
    fail "IULinux identity missing"
fi

if grep -qx 'VERSION_ID="0.1-dev"' "${ROOTFS}/usr/lib/os-release"; then
    pass "IULinux version identity"
else
    fail "Unexpected IULinux version"
fi


section "LEAN DEFAULT POLICY"

OPTIONAL_PACKAGES=(
    llama.cpp
    llama.cpp-tools
    libggml0-backend-blas
    libggml0-backend-vulkan
    pipx
    libopenblas-dev
    libnuma-dev
    nvidia-container-toolkit
)

for pkg in "${OPTIONAL_PACKAGES[@]}"; do
    status="$(
        sudo chroot "${ROOTFS}" \
            dpkg-query -W -f='${db:Status-Abbrev}' "${pkg}" \
            2>/dev/null || true
    )"

    if [[ "${status}" == "ii " ]]; then
        fail "Optional package present in default image: ${pkg}"
    else
        pass "Optional package absent: ${pkg}"
    fi
done

if sudo chroot "${ROOTFS}" \
    dpkg-query -W \
        -f='${binary:Package} ${db:Status-Abbrev}\n' \
        'nvidia-driver-*' 2>/dev/null |
    grep -E '^nvidia-driver-.* ii ' >/dev/null
then
    fail "Proprietary NVIDIA driver present in generic image"
else
    pass "No proprietary NVIDIA driver in generic image"
fi

if sudo chroot "${ROOTFS}" \
    dpkg-query -W \
        -f='${binary:Package} ${db:Status-Abbrev}\n' \
        'cuda-toolkit-*' 2>/dev/null |
    grep -E '^cuda-toolkit-.* ii ' >/dev/null
then
    fail "CUDA toolkit present in generic image"
else
    pass "No CUDA toolkit in generic image"
fi

for f in \
    "${PROJECT_ROOT}/overlay/usr/bin/iulinux-ai-init" \
    "${PROJECT_ROOT}/overlay/usr/bin/iulinux-ai-info"
do
    if [[ -e "${f}" ]]; then
        fail "AI utility leaked into default overlay: ${f##*/}"
    else
        pass "Default overlay excludes ${f##*/}"
    fi
done

for f in \
    "${PROJECT_ROOT}/profiles/ai/overlay/usr/bin/iulinux-ai-init" \
    "${PROJECT_ROOT}/profiles/ai/overlay/usr/bin/iulinux-ai-info"
do
    if [[ -x "${f}" ]]; then
        pass "Optional AI profile retains ${f##*/}"
    else
        fail "Optional AI profile missing ${f##*/}"
    fi
done


section "DEFAULT TEST SUITE"

while IFS= read -r test; do
    name="${test##*/}"

    case "${name}" in
        test-ai-foundation.sh|test-ai-runtime.sh)
            echo "[SKIP] ${name} (optional AI profile)"
            continue
            ;;
    esac

    echo
    echo "--- ${name} ---"

    if "${test}"; then
        pass "${name}"
    else
        fail "${name}"
    fi
done < <(
    find "${PROJECT_ROOT}/tests" \
        -maxdepth 1 \
        -type f \
        -name 'test-*.sh' \
        -perm -u+x \
        -print |
    sort
)


section "ISO"

if [[ -f "${ISO}" ]]; then
    pass "ISO exists"
else
    fail "ISO missing"
fi

if [[ -f "${SHA}" ]]; then
    pass "ISO checksum file exists"

    if (cd "${PROJECT_ROOT}" && sha256sum -c "build/$(basename "${SHA}")"); then
        pass "ISO SHA-256 verified"
    else
        fail "ISO SHA-256 mismatch"
    fi
else
    fail "ISO checksum file missing"
fi

if [[ -f "${ISO}" ]]; then
    ISO_BYTES="$(stat -c '%s' "${ISO}")"
    ISO_MIB=$((ISO_BYTES / 1024 / 1024))

    echo "ISO size: ${ISO_MIB} MiB"

    if (( ISO_MIB <= 4096 )); then
        pass "ISO remains below 4 GiB"
    else
        fail "ISO exceeds 4 GiB lean-release ceiling"
    fi
fi


section "RELEASE SUMMARY"

echo "Commit: ${COMMIT}"

if [[ -f "${ISO}" ]]; then
    echo "ISO:    $(basename "${ISO}")"
    echo "Size:   $(du -h "${ISO}" | awk '{print $1}')"
fi

if [[ -f "${SHA}" ]]; then
    echo "SHA256: $(awk '{print $1}' "${SHA}")"
fi

echo
echo "Passed: ${PASS}"
echo "Failed: ${FAIL}"
echo

if (( FAIL != 0 )); then
    echo "============================================"
    echo " IULinux release gate: FAILED"
    echo "============================================"
    exit 1
fi

echo "============================================"
echo " IULinux release gate: ALL PASSED"
echo "============================================"
