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

make defconfig
echo "==> Preparation complete."