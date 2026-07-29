#!/bin/bash
set -e

echo "==> Copy profile"
cp ../profiles/c50v6-minimal.config .config

echo "==> Apply package list"
while IFS= read -r pkg || [ -n "$pkg" ]; do
    pkg="${pkg%$'\r'}"
    case "$pkg" in
        ""|\#*) continue ;;
        -*)
            name="${pkg#-}"
            sed -i "/^CONFIG_PACKAGE_${name}=y$/d" .config
            sed -i "/^CONFIG_PACKAGE_${name}=m$/d" .config
            grep -qxF "# CONFIG_PACKAGE_${name} is not set" .config || \
                echo "# CONFIG_PACKAGE_${name} is not set" >> .config
            ;;
        *)
            sed -i "/^# CONFIG_PACKAGE_${pkg} is not set$/d" .config
            grep -qxF "CONFIG_PACKAGE_${pkg}=y" .config || \
                echo "CONFIG_PACKAGE_${pkg}=y" >> .config
            ;;
    esac
done < ../profiles/packages.txt

# Cihaz profilinin ezilmemesi garantisi
echo "CONFIG_TARGET_ramips=y" >> .config
echo "CONFIG_TARGET_ramips_mt76x8=y" >> .config
echo "CONFIG_TARGET_ramips_mt76x8_DEVICE_tplink_archer-c50-v6=y" >> .config

echo "==> Generate final config"
make defconfig