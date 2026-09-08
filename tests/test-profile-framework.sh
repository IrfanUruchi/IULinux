#!/usr/bin/env bash
set -Eeuo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOTFS="${PROJECT_ROOT}/build/rootfs"

fail()
{
    echo "[FAIL] IULinux profile framework: $*"
    exit 1
}

PROFILE_ROOT="${ROOTFS}/usr/share/iulinux/profiles/ai"

[[ -x "${ROOTFS}/usr/bin/iulinux-profile" ]] ||
    fail "profile CLI missing"

[[ -f "${PROFILE_ROOT}/profile.conf" ]] ||
    fail "AI profile manifest missing"

[[ -f "${PROFILE_ROOT}/packages.list" ]] ||
    fail "AI profile package manifest missing"

[[ -x "${PROFILE_ROOT}/post-install" ]] ||
    fail "AI profile policy hook missing"

[[ -x "${PROFILE_ROOT}/overlay/usr/bin/iulinux-ai-init" ]] ||
    fail "AI init utility missing from dormant profile"

[[ -x "${PROFILE_ROOT}/overlay/usr/bin/iulinux-ai-info" ]] ||
    fail "AI info utility missing from dormant profile"

bash -n "${ROOTFS}/usr/bin/iulinux-profile" ||
    fail "profile CLI syntax"

bash -n "${PROFILE_ROOT}/post-install" ||
    fail "AI profile post-install syntax"

list_output="$(
    "${PROJECT_ROOT}/scripts/chroot-run.sh" \
        iulinux-profile list
)"

grep -q '^ai' <<<"${list_output}" ||
    fail "AI profile not listed"

info_output="$(
    "${PROJECT_ROOT}/scripts/chroot-run.sh" \
        iulinux-profile info ai
)"

grep -q 'Default:     false' <<<"${info_output}" ||
    fail "AI profile incorrectly marked default"

plan_output="$(
    "${PROJECT_ROOT}/scripts/chroot-run.sh" \
        iulinux-profile plan ai
)"

grep -q 'llama.cpp' <<<"${plan_output}" ||
    fail "AI installation plan incomplete"

status_output="$(
    "${PROJECT_ROOT}/scripts/chroot-run.sh" \
        iulinux-profile status ai
)"

grep -q 'not installed' <<<"${status_output}" ||
    fail "AI profile unexpectedly marked installed"

# Dormant profile assets must NOT become active default utilities.
[[ ! -e "${ROOTFS}/usr/bin/iulinux-ai-init" ]] ||
    fail "AI init leaked into default runtime"

[[ ! -e "${ROOTFS}/usr/bin/iulinux-ai-info" ]] ||
    fail "AI info leaked into default runtime"

# AI runtime must remain absent from default rootfs.
for pkg in \
    llama.cpp \
    llama.cpp-tools \
    libggml0-backend-blas \
    libggml0-backend-vulkan \
    pipx
do
    status="$(
        sudo chroot "${ROOTFS}" \
            dpkg-query -W -f='${db:Status-Abbrev}' "${pkg}" \
            2>/dev/null || true
    )"

    [[ "${status}" != "ii " ]] ||
        fail "${pkg} unexpectedly installed by default"
done

echo "[PASS] IULinux profile framework"

grep -q 'packages-before' \
    "${ROOTFS}/usr/bin/iulinux-profile" ||
    fail "package provenance snapshot missing"

grep -q 'packages-added' \
    "${ROOTFS}/usr/bin/iulinux-profile" ||
    fail "added-package provenance missing"

grep -q 'packages-preexisting' \
    "${ROOTFS}/usr/bin/iulinux-profile" ||
    fail "pre-existing package provenance missing"

grep -q 'overlay-files' \
    "${ROOTFS}/usr/bin/iulinux-profile" ||
    fail "overlay provenance missing"

grep -q 'check_overlay_collisions' \
    "${ROOTFS}/usr/bin/iulinux-profile" ||
    fail "overlay collision protection missing"

grep -Fq 'chmod 0755 "${final_state}"' \
    "${ROOTFS}/usr/bin/iulinux-profile" ||
    fail "profile state directory readability policy missing"

grep -Fq 'chmod 0644 {} +' \
    "${ROOTFS}/usr/bin/iulinux-profile" ||
    fail "profile state file readability policy missing"

echo "[PASS] IULinux profile state permission policy"

echo "[PASS] IULinux profile provenance policy"

[[ -x "${ROOTFS}/usr/lib/iulinux/profile-remove" ]] ||
    fail "profile removal engine missing"

bash -n "${ROOTFS}/usr/lib/iulinux/profile-remove" ||
    fail "profile removal engine syntax"

grep -q 'remove --no-auto-remove' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" ||
    fail "package removal safety gate missing"

grep -q 'Modified profile file preserved' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" ||
    fail "modified-file preservation missing"

grep -q 'Provenance archived' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" ||
    fail "removal provenance archive missing"

echo "[PASS] IULinux safe profile removal policy"

grep -q 'Dependency cleanup would remove package not introduced by profile' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" ||
    fail "dependency autoremove safety gate missing"

[[ "$(
    grep -c '# Archive provenance instead of deleting profile history.' \
        "${ROOTFS}/usr/lib/iulinux/profile-remove"
)" -eq 1 ]] ||
    fail "profile remover must contain exactly one archive block"

echo "[PASS] IULinux profile lifecycle cleanup policy"

grep -q 'architectures-requested' \
    "${ROOTFS}/usr/bin/iulinux-profile" ||
    fail "requested-architecture provenance missing"

grep -q 'architectures-before' \
    "${ROOTFS}/usr/bin/iulinux-profile" ||
    fail "architecture baseline provenance missing"

grep -q 'architectures-added' \
    "${ROOTFS}/usr/bin/iulinux-profile" ||
    fail "added-architecture provenance missing"

grep -q 'dpkg --add-architecture' \
    "${ROOTFS}/usr/bin/iulinux-profile" ||
    fail "profile architecture enablement missing"

grep -q 'Best-effort rollback of architectures introduced by a failed install' \
    "${ROOTFS}/usr/bin/iulinux-profile" ||
    fail "failed-install architecture rollback missing"

grep -q 'Architecture preserved; required by another profile' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" ||
    fail "cross-profile architecture preservation missing"

grep -q 'Architecture preserved; package not owned by profile' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" ||
    fail "unowned installed-package architecture safety gate missing"

grep -q 'dpkg --remove-architecture' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" ||
    fail "safe architecture cleanup missing"

remove_engine="${ROOTFS}/usr/lib/iulinux/profile-remove"

grep -qF 'package_id()' "${remove_engine}" ||
    fail "architecture-aware package identity missing"

grep -qF 'Foreign-architecture teardown safety gate' "${remove_engine}" ||
    fail "foreign-architecture teardown safety gate missing"

grep -qF 'Foreign-architecture teardown would remove another architecture' "${remove_engine}" ||
    fail "cross-architecture teardown protection missing"

grep -qF 'Foreign-architecture teardown would remove package not introduced by profile' "${remove_engine}" ||
    fail "foreign-architecture provenance protection missing"

grep -qF -- '--allow-remove-essential' "${remove_engine}" ||
    fail "guarded foreign essential-package teardown missing"

gate_line="$(grep -nF 'Foreign-architecture teardown safety gate' "${remove_engine}" | head -1 | cut -d: -f1)"
override_line="$(grep -nF -- '--allow-remove-essential' "${remove_engine}" | head -1 | cut -d: -f1)"
verify_line="$(grep -nF 'Foreign architecture still has installed packages after teardown' "${remove_engine}" | head -1 | cut -d: -f1)"
remove_arch_line="$(grep -nF 'dpkg --remove-architecture' "${remove_engine}" | head -1 | cut -d: -f1)"

[[ -n "${gate_line}" &&
   -n "${override_line}" &&
   -n "${verify_line}" &&
   -n "${remove_arch_line}" &&
   "${gate_line}" -lt "${override_line}" &&
   "${override_line}" -lt "${verify_line}" &&
   "${verify_line}" -lt "${remove_arch_line}" ]] ||
    fail "foreign-architecture teardown safety ordering invalid"

echo "[PASS] IULinux guarded foreign-architecture teardown policy"

grep -qF 'Residual profile package cleanup safety gate' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" ||
    fail "residual package cleanup safety gate missing"

grep -qF 'Residual cleanup would remove package not introduced by profile' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" ||
    fail "residual package provenance protection missing"

grep -qF 'Residual profile package remains installed' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" ||
    fail "residual package post-removal verification missing"

grep -qF '"${pkg_arch}" == "${native_arch}" || "${pkg_arch}" == "all"' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" ||
    fail "residual cleanup native/all architecture restriction missing"

foreign_line="$(grep -nF 'Removed unused profile-added architecture' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" | head -1 | cut -d: -f1)"
residual_line="$(grep -nF 'Residual profile package cleanup safety gate' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" | head -1 | cut -d: -f1)"
archive_line="$(grep -nF 'Archive provenance instead of deleting profile history' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" | head -1 | cut -d: -f1)"

[[ -n "${foreign_line}" &&
   -n "${residual_line}" &&
   -n "${archive_line}" &&
   "${foreign_line}" -lt "${residual_line}" &&
   "${residual_line}" -lt "${archive_line}" ]] ||
    fail "residual cleanup safety ordering invalid"

echo "[PASS] IULinux guarded residual package cleanup policy"

grep -qF 'rc_purged="${state}/rc-purged"' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" ||
    fail "residual config purge provenance missing"

grep -qF 'rc_preserved="${state}/rc-preserved"' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" ||
    fail "residual config preservation provenance missing"

grep -qF '[[ "${status}" == rc* ]] || continue' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" ||
    fail "residual config cleanup not restricted to rc state"

grep -qF 'Residual config preserved; modified conffile' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" ||
    fail "modified residual conffile preservation missing"

grep -qF 'Residual config preserved; shared conffile ownership mismatch' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" ||
    fail "shared residual conffile safety gate missing"

grep -qF 'Shared conffile disappeared after residual purge' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" ||
    fail "shared conffile post-purge existence verification missing"

grep -qF 'Shared conffile changed after residual purge' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" ||
    fail "shared conffile post-purge hash verification missing"

grep -qF 'Residual dpkg config cleanup completed' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" ||
    fail "residual dpkg config cleanup completion missing"

residual_pkg_line="$(grep -nF 'Removed residual profile-added packages' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" | head -1 | cut -d: -f1)"
rc_line="$(grep -nF 'Residual dpkg config cleanup completed' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" | head -1 | cut -d: -f1)"
archive_line="$(grep -nF 'Archive provenance instead of deleting profile history' \
    "${ROOTFS}/usr/lib/iulinux/profile-remove" | head -1 | cut -d: -f1)"

[[ -n "${residual_pkg_line}" &&
   -n "${rc_line}" &&
   -n "${archive_line}" &&
   "${residual_pkg_line}" -lt "${rc_line}" &&
   "${rc_line}" -lt "${archive_line}" ]] ||
    fail "residual dpkg config cleanup ordering invalid"

echo "[PASS] IULinux guarded residual dpkg config purge policy"

echo "[PASS] IULinux profile architecture lifecycle policy"
