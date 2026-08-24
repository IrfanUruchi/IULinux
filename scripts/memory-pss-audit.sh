#!/usr/bin/env bash
set -Eeuo pipefail

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT

for proc in /proc/[0-9]*; do
    pid="${proc##*/}"

    [[ -r "${proc}/smaps_rollup" ]] || continue
    [[ -r "${proc}/comm" ]] || continue

    name="$(cat "${proc}/comm" 2>/dev/null || true)"
    [[ -n "${name}" ]] || continue

    pss="$(
        awk '/^Pss:/ {print $2; exit}' \
            "${proc}/smaps_rollup" 2>/dev/null || true
    )"

    [[ "${pss}" =~ ^[0-9]+$ ]] || continue

    printf '%s\t%s\t%s\n' \
        "${pss}" \
        "${pid}" \
        "${name}" >> "${tmp}"
done

echo "=== TOP PROCESSES BY PSS ==="

sort -nr "${tmp}" |
    head -n 25 |
    awk '{
        printf "%8.1f MiB  PID %-7s %s\n",
               $1 / 1024, $2, $3
    }'

echo
echo "=== TOTAL MEASURED PSS ==="

awk '{sum += $1} END {
    printf "%.1f MiB\n", sum / 1024
}' "${tmp}"
