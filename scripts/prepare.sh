#!/bin/bash
set -e

echo "==> Copy profile"
cp ../profiles/c50v6-minimal.config .config

echo "==> Apply package list"
while read -r pkg; do
    [ -z "$pkg" ] && continue
    case "$pkg" in
        \#*) continue ;;
        -*)
            sed -i "/CONFIG_PACKAGE_${pkg#-}=y/d" .config
            ;;
        *)
            echo "CONFIG_PACKAGE_${pkg}=y" >> .config
            ;;
    esac
done < ../profiles/packages.txt

echo "==> Generate final config"
make defconfig