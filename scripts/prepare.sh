#!/bin/bash
set -e

echo "==> Preparing build environment..."

# Create directories
mkdir -p files/etc/uci-defaults
mkdir -p files/etc/init.d
mkdir -p files/usr/bin
mkdir -p files/opt/zapret

# Copy profile config
cp ../profiles/c50v6-minimal.config .config

# Apply package list
while IFS= read -r line || [[ -n "$line" ]]; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    
    if [[ "$line" == -* ]]; then
        pkg="${line:1}"
        echo "CONFIG_PACKAGE_${pkg}=n" >> .config
    else
        echo "CONFIG_PACKAGE_${line}=y" >> .config
    fi
done < ../profiles/packages.txt

# ============================================
# PATCH: Sert bağımlılıkları kaldır
# ============================================
sed -i 's/ +opkg//' package/system/base-files/Makefile
sed -i 's/ +procd-ujail//' package/system/procd/Makefile
sed -i 's/ +procd-seccomp//' package/system/procd/Makefile
sed -i 's/ +odhcp6c//' package/network/config/netifd/Makefile
echo "==> Dependency patches applied"

# Generate final config
make defconfig

echo "==> Preparation complete."