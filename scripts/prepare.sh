#!/bin/bash
set -e
echo "==> Copy profile"
cp ../profiles/c50v6-minimal.config .config
echo "==> Apply package list"
while IFS= read -r pkg; do
    case "$pkg" in
        ""|\#*) continue ;;
        -*)
            name="${pkg#-}"
            # Once varsa =y satirini sil
            sed -i "/^CONFIG_PACKAGE_${name}=y$/d" .config
            sed -i "/^CONFIG_PACKAGE_${name}=m$/d" .config
            # Sonra acikca devre disi birak (device default packages icin sart)
            grep -qxF "# CONFIG_PACKAGE_${name} is not set" .config || \
                echo "# CONFIG_PACKAGE_${name} is not set" >> .config
            ;;
        *)
            # Once varsa disable satirini sil
            sed -i "/^# CONFIG_PACKAGE_${pkg} is not set$/d" .config
            grep -qxF "CONFIG_PACKAGE_${pkg}=y" .config || \
                echo "CONFIG_PACKAGE_${pkg}=y" >> .config
            ;;
    esac
done < ../profiles/packages.txt
echo "==> Generate final config"
make defconfig