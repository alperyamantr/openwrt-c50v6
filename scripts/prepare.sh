#!/bin/bash
set -e

OPENWRT_DIR="openwrt"
TARGET_CONFIG="target/linux/ramips/mt76x8/config-6.12"

echo "==> Patching kernel config: $TARGET_CONFIG"

# SWAP
if ! grep -q "^CONFIG_SWAP=y" "$OPENWRT_DIR/$TARGET_CONFIG"; then
    echo "CONFIG_SWAP=y" >> "$OPENWRT_DIR/$TARGET_CONFIG"
    echo "OK: CONFIG_SWAP=y added"
fi

# TCP Westwood
if ! grep -q "^CONFIG_TCP_CONG_ADVANCED=y" "$OPENWRT_DIR/$TARGET_CONFIG"; then
    echo "CONFIG_TCP_CONG_ADVANCED=y" >> "$OPENWRT_DIR/$TARGET_CONFIG"
fi

if ! grep -q "^CONFIG_TCP_CONG_WESTWOOD=y" "$OPENWRT_DIR/$TARGET_CONFIG"; then
    echo "CONFIG_TCP_CONG_WESTWOOD=y" >> "$OPENWRT_DIR/$TARGET_CONFIG"
fi

if ! grep -q "^CONFIG_DEFAULT_WESTWOOD=y" "$OPENWRT_DIR/$TARGET_CONFIG"; then
    echo "CONFIG_DEFAULT_WESTWOOD=y" >> "$OPENWRT_DIR/$TARGET_CONFIG"
    echo 'CONFIG_DEFAULT_TCP_CONG="westwood"' >> "$OPENWRT_DIR/$TARGET_CONFIG"
    echo "OK: Westwood added"
fi

echo "==> Done"