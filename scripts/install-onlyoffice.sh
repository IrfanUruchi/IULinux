#!/usr/bin/env bash
set -Eeuo pipefail

trap 'echo "[IULinux] ERROR: ONLYOFFICE installation failed at line ${LINENO}" >&2' ERR

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS_DIR="${PROJECT_ROOT}/build/rootfs"
CHROOT_RUN="${PROJECT_ROOT}/scripts/chroot-run.sh"

KEY_URL="https://download.onlyoffice.com/GPG-KEY-ONLYOFFICE"
KEYRING="${ROOTFS_DIR}/usr/share/keyrings/onlyoffice.gpg"
SOURCE_LIST="${ROOTFS_DIR}/etc/apt/sources.list.d/onlyoffice.list"

[[ -d "${ROOTFS_DIR}" ]] || {
    echo "[IULinux] Rootfs missing." >&2
    exit 1
}

for command in curl gpg sudo; do
    command -v "${command}" >/dev/null 2>&1 || {
        echo "[IULinux] Required host command missing: ${command}" >&2
        exit 1
    }
done

sudo -v

echo "============================================"
echo " IULinux ONLYOFFICE installation"
echo "============================================"

TMPDIR="$(mktemp -d)"

cleanup()
{
    rm -rf "${TMPDIR}"
}

trap cleanup EXIT

echo
echo "[IULinux] Downloading ONLYOFFICE signing key..."

curl -fsSL \
    "${KEY_URL}" \
    -o "${TMPDIR}/onlyoffice.key"

echo "[IULinux] Verifying vendor key identity..."

FINGERPRINT="$(
    gpg \
        --batch \
        --show-keys \
        --with-colons \
        "${TMPDIR}/onlyoffice.key" |
        awk -F: '$1 == "fpr" {print $10; exit}'
)"

case "${FINGERPRINT}" in
    *8320CA65CB2DE8E5)
        ;;
    *)
        echo "[IULinux] Unexpected ONLYOFFICE signing-key fingerprint:" >&2
        echo "          ${FINGERPRINT:-unknown}" >&2
        exit 1
        ;;
esac

echo "[IULinux] Installing signing key..."

gpg \
    --batch \
    --yes \
    --dearmor \
    --output "${TMPDIR}/onlyoffice.gpg" \
    "${TMPDIR}/onlyoffice.key"

sudo install \
    -o root \
    -g root \
    -m 0644 \
    "${TMPDIR}/onlyoffice.gpg" \
    "${KEYRING}"

echo "[IULinux] Configuring ONLYOFFICE repository..."

echo \
'deb [signed-by=/usr/share/keyrings/onlyoffice.gpg] https://download.onlyoffice.com/repo/debian squeeze main' |
    sudo tee "${SOURCE_LIST}" >/dev/null

sudo chmod 0644 "${SOURCE_LIST}"

echo
echo "[IULinux] Updating package metadata..."

"${CHROOT_RUN}" apt-get update

echo
echo "[IULinux] Repository candidate:"

"${CHROOT_RUN}" apt-cache policy onlyoffice-desktopeditors

CANDIDATE="$(
    "${CHROOT_RUN}" apt-cache policy onlyoffice-desktopeditors |
        awk '/Candidate:/ {print $2; exit}'
)"

if [[ -z "${CANDIDATE}" || "${CANDIDATE}" == "(none)" ]]; then
    echo "[IULinux] ONLYOFFICE package has no installation candidate." >&2
    exit 1
fi

echo
echo "[IULinux] Installing ONLYOFFICE Desktop Editors..."

"${CHROOT_RUN}" \
    /usr/bin/env \
    DEBIAN_FRONTEND=noninteractive \
    apt-get install \
        -y \
        --no-install-recommends \
        onlyoffice-desktopeditors

echo
echo "[IULinux] Cleaning package cache..."

"${CHROOT_RUN}" apt-get clean

echo
echo "[IULinux] Re-applying IULinux overlay..."

"${PROJECT_ROOT}/scripts/apply-overlay.sh"

echo
echo "============================================"
echo " ONLYOFFICE installation COMPLETE"
echo "============================================"

"${CHROOT_RUN}" \
    dpkg-query \
    -W \
    -f='${Package}\t${Version}\n' \
    onlyoffice-desktopeditors
