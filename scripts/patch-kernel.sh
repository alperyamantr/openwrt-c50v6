#!/bin/bash
set -e

OPENWRT_DIR="openwrt"
TARGET_CONFIG="target/linux/ramips/mt76x8/config-6.12"

echo "==> Patching kernel config: $TARGET_CONFIG"

# SWAP (ZRAM için zorunlu) — önce var olanı sil, sonra ekle
sed -i '/^CONFIG_SWAP/d' "$OPENWRT_DIR/$TARGET_CONFIG"
echo "CONFIG_SWAP=y" >> "$OPENWRT_DIR/$TARGET_CONFIG"
echo "OK: CONFIG_SWAP=y set"

# TCP Congestion Advanced — önce var olanı sil, sonra ekle
sed -i '/^CONFIG_TCP_CONG_ADVANCED/d' "$OPENWRT_DIR/$TARGET_CONFIG"
echo "CONFIG_TCP_CONG_ADVANCED=y" >> "$OPENWRT_DIR/$TARGET_CONFIG"

# TCP Westwood built-in — önce var olanı sil, sonra ekle
sed -i '/^CONFIG_TCP_CONG_WESTWOOD/d' "$OPENWRT_DIR/$TARGET_CONFIG"
echo "CONFIG_TCP_CONG_WESTWOOD=y" >> "$OPENWRT_DIR/$TARGET_CONFIG"

# Default congestion control — önce var olanı sil, sonra ekle
sed -i '/^CONFIG_DEFAULT_TCP_CONG/d' "$OPENWRT_DIR/$TARGET_CONFIG"
echo 'CONFIG_DEFAULT_TCP_CONG="westwood"' >> "$OPENWRT_DIR/$TARGET_CONFIG"
echo "OK: Westwood default congestion control set"

echo "==> Done"