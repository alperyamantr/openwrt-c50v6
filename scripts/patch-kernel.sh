#!/bin/bash
set -e

OPENWRT_DIR="openwrt"
TARGET_CONFIG="target/linux/ramips/mt76x8/config-6.12"

echo "==> Patching kernel config: $TARGET_CONFIG"

# SWAP (ZRAM için zorunlu)
sed -i '/^CONFIG_SWAP/d' "$OPENWRT_DIR/$TARGET_CONFIG"
echo "CONFIG_SWAP=y" >> "$OPENWRT_DIR/$TARGET_CONFIG"
echo "OK: CONFIG_SWAP=y set"

# TCP Congestion Advanced
sed -i '/^CONFIG_TCP_CONG_ADVANCED/d' "$OPENWRT_DIR/$TARGET_CONFIG"
echo "CONFIG_TCP_CONG_ADVANCED=y" >> "$OPENWRT_DIR/$TARGET_CONFIG"

# TCP Westwood built-in
sed -i '/^CONFIG_TCP_CONG_WESTWOOD/d' "$OPENWRT_DIR/$TARGET_CONFIG"
echo "CONFIG_TCP_CONG_WESTWOOD=y" >> "$OPENWRT_DIR/$TARGET_CONFIG"

# Default congestion control - TÜM choice option'larını sil
sed -i '/^CONFIG_DEFAULT_CUBIC/d' "$OPENWRT_DIR/$TARGET_CONFIG"
sed -i '/^CONFIG_DEFAULT_RENO/d' "$OPENWRT_DIR/$TARGET_CONFIG"
sed -i '/^CONFIG_DEFAULT_WESTWOOD/d' "$OPENWRT_DIR/$TARGET_CONFIG"
sed -i '/^CONFIG_DEFAULT_TCP_CONG/d' "$OPENWRT_DIR/$TARGET_CONFIG"

# Sadece Westwood'u aktif et (choice bloğunda tek seçenek)
echo "CONFIG_DEFAULT_WESTWOOD=y" >> "$OPENWRT_DIR/$TARGET_CONFIG"
echo "OK: Westwood default congestion control set"

echo "==> Done"