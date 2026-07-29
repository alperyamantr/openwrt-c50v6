#!/bin/bash
set -e

OPENWRT_DIR="openwrt"
TARGET_DIR="$OPENWRT_DIR/target/linux/ramips/mt76x8"

echo "==> Patching kernel configs in: $TARGET_DIR"

for TARGET_CONFIG in "$TARGET_DIR"/config-6.*; do
    [ -f "$TARGET_CONFIG" ] || continue
    echo "Processing $TARGET_CONFIG..."

    # SWAP (ZRAM için zorunlu)
    sed -i '/^CONFIG_SWAP/d' "$TARGET_CONFIG"
    echo "CONFIG_SWAP=y" >> "$TARGET_CONFIG"

    # TCP Congestion Advanced
    sed -i '/^CONFIG_TCP_CONG_ADVANCED/d' "$TARGET_CONFIG"
    echo "CONFIG_TCP_CONG_ADVANCED=y" >> "$TARGET_CONFIG"

    # TCP Westwood built-in
    sed -i '/^CONFIG_TCP_CONG_WESTWOOD/d' "$TARGET_CONFIG"
    echo "CONFIG_TCP_CONG_WESTWOOD=y" >> "$TARGET_CONFIG"

    # Default congestion control choice temizliği
    sed -i '/^CONFIG_DEFAULT_CUBIC/d' "$TARGET_CONFIG"
    sed -i '/^CONFIG_DEFAULT_RENO/d' "$TARGET_CONFIG"
    sed -i '/^CONFIG_DEFAULT_WESTWOOD/d' "$TARGET_CONFIG"
    sed -i '/^CONFIG_DEFAULT_TCP_CONG/d' "$TARGET_CONFIG"

    echo "CONFIG_DEFAULT_WESTWOOD=y" >> "$TARGET_CONFIG"
done

echo "==> Done patching kernel configs"