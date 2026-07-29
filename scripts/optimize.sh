#!/bin/bash
set -e

echo "==> Optimizing build..."

find . -type f \( -name "*.orig" -o -name "*.rej" \) -delete
chmod +x ../scripts/*.sh
find ./files/etc/init.d ./files/etc/uci-defaults ./files/usr/bin -type f -exec chmod +x {} + 2>/dev/null || true
chmod +x ./files/opt/zapret/nfqws 2>/dev/null || true

echo "==> Kernel config optimizations"
cat >> .config << 'EOF'

# ZRAM için SWAP desteği
CONFIG_KERNEL_SWAP=y

# Debug/Profil çıkar - boyut küçült
CONFIG_KERNEL_DEBUG_INFO=n
CONFIG_KERNEL_DEBUG_KERNEL=n
CONFIG_KERNEL_CRASHLOG=n
CONFIG_KERNEL_ELF_CORE=n
CONFIG_KERNEL_PROVE_LOCKING=n
CONFIG_KERNEL_SECCOMP=n

# Sıkıştırma optimizasyonu (Hatalı 512 bayt parametresi DÜZELTİLDİ)
CONFIG_TARGET_SQUASHFS_BLOCK_SIZE_512K=y
CONFIG_USE_MKLIBS=y
CONFIG_STRIP_KERNEL_EXPORTS=y

# Incremental build hızlandırma
CONFIG_CCACHE=y
EOF

echo "==> Optimization complete."