#!/bin/bash
set -e

echo "==> Copy profile"
cp ../profiles/c50v6-minimal.config .config

echo "==> Apply package list"
while IFS= read -r pkg; do
    case "$pkg" in
        ""|\#*) continue ;;
        -*)
            sed -i "/^CONFIG_PACKAGE_${pkg#-}=y$/d" .config
            ;;
        *)
            grep -qxF "CONFIG_PACKAGE_${pkg}=y" .config || \
                echo "CONFIG_PACKAGE_${pkg}=y" >> .config
            ;;
    esac
done < ../profiles/packages.txt

echo "==> Generate final config"
make defconfig