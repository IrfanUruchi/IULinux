#!/usr/bin/env bash
set -Eeuo pipefail

echo "============================================"
echo " IULinux runtime audit"
echo "============================================"

echo
echo "=== OS ==="
cat /etc/os-release

echo
echo "=== SESSION ==="
echo "Type: ${XDG_SESSION_TYPE:-unknown}"
echo "Desktop: ${XDG_CURRENT_DESKTOP:-unknown}"

echo
echo "=== MEMORY ==="
free -h

echo
echo "=== TOP MEMORY PROCESSES ==="
ps -eo pid,comm,rss,%mem,%cpu \
    --sort=-rss |
    head -n 26

echo
echo "=== RUNNING SYSTEM SERVICES ==="
systemctl \
    list-units \
    --type=service \
    --state=running \
    --no-pager

echo
echo "=== ENABLED SYSTEM SERVICES ==="
systemctl \
    list-unit-files \
    --type=service \
    --state=enabled \
    --no-pager

echo
echo "=== RUNNING USER SERVICES ==="
systemctl --user \
    list-units \
    --type=service \
    --state=running \
    --no-pager \
    2>/dev/null || true

echo
echo "=== ENABLED USER SERVICES ==="
systemctl --user \
    list-unit-files \
    --type=service \
    --state=enabled \
    --no-pager \
    2>/dev/null || true

echo
echo "=== XDG AUTOSTART ==="
find /etc/xdg/autostart "${HOME}/.config/autostart" \
    -maxdepth 1 \
    -type f \
    -name '*.desktop' \
    -print \
    2>/dev/null |
    sort

echo
echo "=== FAILED UNITS ==="
systemctl --failed --no-pager

echo
echo "=== BOOT ==="
systemd-analyze time 2>/dev/null || true

echo
echo "=== SLOWEST BOOT UNITS ==="
systemd-analyze blame 2>/dev/null |
    head -n 25 || true

echo
echo "=== LARGEST PACKAGES ==="
dpkg-query \
    -W \
    -f='${Installed-Size}\t${binary:Package}\n' |
    sort -nr |
    head -n 30 |
    awk '{
        printf "%8.1f MiB  %s\n", $1 / 1024, $2
    }'

echo
echo "=== FILESYSTEM ==="
df -h /

echo
echo "=== MAJOR DIRECTORY SIZES ==="
du -sh /usr /opt /var 2>/dev/null || true

echo
echo "=== NETWORK ==="
nmcli general status 2>/dev/null || true

echo
echo "============================================"
echo " Audit complete"
echo "============================================"
