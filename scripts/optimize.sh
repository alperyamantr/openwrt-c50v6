#!/bin/bash
set -e

echo "==> Optimizing build..."

# Remove temporary patch files
find . -type f \( -name "*.orig" -o -name "*.rej" \) -delete

# Ensure build scripts are executable
chmod +x ../scripts/*.sh

# Ensure OpenWrt custom scripts are executable
find ./files/etc/init.d ./files/etc/uci-defaults ./files/usr/bin -type f -exec chmod +x {} + 2>/dev/null || true

# Ensure nfqws is executable
chmod +x ./files/opt/zapret/nfqws 2>/dev/null || true

# Kernel config optimizations (C50 V6 için)
echo "==> Kernel config optimizations"
cat >> .config << 'EOF'
# IPv6 tamamen devre dışı
CONFIG_IPV6=n

# Debug/Profil çıkar (kernel boyutu düşer)
CONFIG_KERNEL_DEBUG_INFO=n
CONFIG_KERNEL_DEBUG_KERNEL=n
CONFIG_KERNEL_KALLSYMS=n
CONFIG_KERNEL_CRASHLOG=n
CONFIG_KERNEL_ELF_CORE=n
CONFIG_KERNEL_PROVE_LOCKING=n
CONFIG_KERNEL_SECCOMP=n
CONFIG_KERNEL_NAMESPACES=n
CONFIG_KERNEL_CGROUPS=n
CONFIG_KERNEL_SWAP=n

# Sıkıştırma optimizasyonu
CONFIG_TARGET_SQUASHFS_BLOCK_SIZE=512
CONFIG_USE_MKLIBS=y
CONFIG_STRIP_KERNEL_EXPORTS=y

# ZRAM için
CONFIG_ZSMALLOC=y
CONFIG_ZRAM=y
CONFIG_ZRAM_DEF_COMP_LZ4=y
EOF

make defconfig

echo "==> Optimization complete."