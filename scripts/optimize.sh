#!/bin/bash
set -e

echo "==> Optimizing build..."

# Remove temporary patch files
find . -name "*.orig" -delete
find . -name "*.rej" -delete

# Ensure scripts are executable
chmod +x ../scripts/*.sh

# Ensure custom files are executable
[ -d ./files/etc/init.d ] && find ./files/etc/init.d -type f -exec chmod +x {} +
[ -d ./files/etc/uci-defaults ] && find ./files/etc/uci-defaults -type f -exec chmod +x {} +
[ -d ./files/usr/bin ] && find ./files/usr/bin -type f -exec chmod +x {} +
[ -f ./files/opt/zapret/nfqws ] && chmod +x ./files/opt/zapret/nfqws

echo "==> Optimization complete."