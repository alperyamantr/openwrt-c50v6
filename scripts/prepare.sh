#!/bin/bash
set -e
echo "==> Copy profile"
cp ../profiles/c50v6-minimal.config .config
echo "==> Apply package list"
while IFS= read -r pkg || [ -n "$pkg" ]; do
    # Windows CRLF temizligi - \r karakterini kaldir
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
echo "==> Generate final config"
make defconfig