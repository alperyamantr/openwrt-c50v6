#!/bin/bash
set -e

echo "==> Optimizing build..."

# Remove temporary patch files
find . -type f \( -name "*.orig" -o -name "*.rej" \) -delete

# Ensure build scripts are executable
chmod +x ../scripts/*.sh

# Ensure OpenWrt custom scripts are executable
find ./files/etc/init.d ./files/etc/uci-defaults ./files/usr/bin -type f -exec chmod +x {} + 2>/dev/null || true

# Ensure nfqws is executable
chmod +x ./files/opt/zapret/nfqws 2>/dev/null || true

echo "==> Optimization complete."