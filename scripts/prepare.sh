#!/bin/bash
set -e

echo "==> Preparing build environment..."

mkdir -p files/etc/uci-defaults
mkdir -p files/etc/init.d
mkdir -p files/usr/bin
mkdir -p files/opt/zapret

cp ../profiles/c50v6-minimal.config .config

while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    if [[ "$line" == -* ]]; then
        pkg="${line:1}"
        echo "CONFIG_PACKAGE_${pkg}=n" >> .config
    else
        echo "CONFIG_PACKAGE_${line}=y" >> .config
    fi
done < ../profiles/packages.txt

# Kernel swap desteğini aç (ZRAM için ZORUNLU)
echo "==> Enabling kernel SWAP..."
for cfg in target/linux/ramips/mt76x8/config-*; do
    if [ -f "$cfg" ]; then
        echo "Found: $cfg"
        if grep -q "CONFIG_SWAP" "$cfg"; then
            sed -i 's/# CONFIG_SWAP is not set/CONFIG_SWAP=y/' "$cfg"
            sed -i 's/CONFIG_SWAP=n/CONFIG_SWAP=y/' "$cfg"
        else
            echo "CONFIG_SWAP=y" >> "$cfg"
        fi
        grep "^CONFIG_SWAP=y" "$cfg" && echo "OK: SWAP enabled in $cfg" || echo "FAIL!"
    fi
done

make defconfig
echo "==> Preparation complete."