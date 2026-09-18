#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

[[ $# -ge 1 && $# -le 2 ]] || {
    echo "Usage: $0 <package-name> [source-dir]"
    exit 2
}

name="$1"
src="${2:-${PROJECT_ROOT}/packaging/${name}}"
control="${src}/DEBIAN/control"
rootfs="${src}/rootfs"

[[ -f "${control}" ]] || {
    echo "[FAIL] Missing control file: ${control}"
    exit 1
}

[[ -d "${rootfs}" ]] || {
    echo "[FAIL] Missing package rootfs: ${rootfs}"
    exit 1
}

version="$(awk -F': *' '$1 == "Version" {print $2; exit}' "${control}")"
arch="$(awk -F': *' '$1 == "Architecture" {print $2; exit}' "${control}")"

outdir="${PROJECT_ROOT}/build/packages"
stage="$(mktemp -d)"

cleanup()
{
    rm -rf "${stage}"
}
trap cleanup EXIT

mkdir -p "${outdir}" "${stage}/DEBIAN"

cp -a "${src}/DEBIAN/." "${stage}/DEBIAN/"
cp -a "${rootfs}/." "${stage}/"

chmod -R go-w "${stage}"

outfile="${outdir}/${name}_${version}_${arch}.deb"

dpkg-deb \
    --root-owner-group \
    --build \
    "${stage}" \
    "${outfile}"

echo "[PASS] Built ${outfile}"
