#!/bin/bash
set -e

echo "==> Optimizing build..."

# Remove temporary patch files
find . -name "*.orig" -delete
find . -name "*.rej" -delete

# Ensure scripts are executable
chmod +x ../scripts/*.sh

# Ensure custom files are executable
[ -f ./files/etc/init.d/zapret ] && chmod +x ./files/etc/init.d/zapret
[ -f ./files/usr/bin/hagezi-guncelle ] && chmod +x ./files/usr/bin/hagezi-guncelle
[ -f ./files/usr/bin/siteekle ] && chmod +x ./files/usr/bin/siteekle
[ -f ./files/opt/zapret/nfqws ] && chmod +x ./files/opt/zapret/nfqws

echo "==> Optimization complete."