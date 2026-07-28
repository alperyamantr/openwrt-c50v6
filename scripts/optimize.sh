#!/bin/bash
set -e

echo "==> Optimizing build..."

find . -type f \( -name "*.orig" -o -name "*.rej" \) -delete
chmod +x ../scripts/*.sh
find ./files/etc/init.d ./files/etc/uci-defaults ./files/usr/bin -type f -exec chmod +x {} + 2>/dev/null || true
chmod +x ./files/opt/zapret/nfqws 2>/dev/null || true

echo "==> Kernel config optimizations"
cat >> .config << 'EOF'

# ZRAM için SWAP desteği (ZORUNLU)
CONFIG_KERNEL_SWAP=y

# Debug/Profil çıkar - boyut küçült
CONFIG_KERNEL_DEBUG_INFO=n
CONFIG_KERNEL_DEBUG_KERNEL=n
CONFIG_KERNEL_CRASHLOG=n
CONFIG_KERNEL_ELF_CORE=n
CONFIG_KERNEL_PROVE_LOCKING=n
CONFIG_KERNEL_SECCOMP=n

# KALLSYMS KAPATMA - symtab.h hatasına yol açar
# CONFIG_KERNEL_KALLSYMS=n

# Sıkıştırma optimizasyonu
CONFIG_TARGET_SQUASHFS_BLOCK_SIZE=512
CONFIG_USE_MKLIBS=y
CONFIG_STRIP_KERNEL_EXPORTS=y

# ZRAM kernel config'leri - OpenWrt .config'inde CONFIG_KERNEL_ prefix'i gerekir
# Ama kmod-zram zaten packages.txt'te, gerek yok
# CONFIG_KERNEL_ZSMALLOC=y
# CONFIG_KERNEL_ZRAM=y
# CONFIG_KERNEL_ZRAM_DEF_COMP_LZ4=y
EOF

echo "==> Optimization complete."