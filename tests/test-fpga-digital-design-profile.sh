#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${PROJECT_ROOT}/build/rootfs"
PROFILE_ROOT="${ROOTFS}/usr/share/iulinux/profiles/fpga-digital-design"

fail()
{
    echo "[FAIL] IULinux FPGA / Digital Design profile: $*"
    exit 1
}

[[ -f "${PROFILE_ROOT}/profile.conf" ]] ||
    fail "profile manifest missing"

[[ -f "${PROFILE_ROOT}/packages.list" ]] ||
    fail "package manifest missing"

[[ ! -e "${PROFILE_ROOT}/architectures.list" ]] ||
    fail "unexpected architecture manifest"

list_output="$("${PROJECT_ROOT}/scripts/chroot-run.sh" iulinux-profile list)"
grep -q '^fpga-digital-design' <<<"${list_output}" ||
    fail "profile not listed"

info_output="$("${PROJECT_ROOT}/scripts/chroot-run.sh" iulinux-profile info fpga-digital-design)"
grep -q 'Default:     false' <<<"${info_output}" ||
    fail "profile incorrectly marked default"

plan_output="$("${PROJECT_ROOT}/scripts/chroot-run.sh" iulinux-profile plan fpga-digital-design)"

for pkg in \
    iverilog \
    verilator \
    ghdl \
    yosys \
    gtkwave \
    nextpnr-ice40 \
    nextpnr-ecp5 \
    openfpgaloader
do
    grep -q "${pkg}" <<<"${plan_output}" ||
        fail "missing package in plan: ${pkg}"
done

grep -q 'Required architectures:' <<<"${plan_output}" ||
    fail "architecture section missing from plan"

grep -q '  none' <<<"${plan_output}" ||
    fail "unexpected architecture requirement"

status_output="$("${PROJECT_ROOT}/scripts/chroot-run.sh" iulinux-profile status fpga-digital-design)"
grep -q 'not installed' <<<"${status_output}" ||
    fail "profile unexpectedly installed"

for pkg in \
    iverilog \
    verilator \
    ghdl \
    yosys \
    gtkwave \
    nextpnr-ice40 \
    nextpnr-ecp5 \
    openfpgaloader
do
    status="$(
        "${PROJECT_ROOT}/scripts/chroot-run.sh" \
            dpkg-query -W -f='${db:Status-Abbrev}' \
            "${pkg}" 2>/dev/null || true
    )"

    [[ "${status}" != ii* ]] ||
        fail "FPGA package leaked into default rootfs: ${pkg}"
done

echo "[PASS] IULinux FPGA / Digital Design profile"
