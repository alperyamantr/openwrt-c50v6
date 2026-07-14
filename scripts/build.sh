#!/bin/bash
set -e

OPENWRT_DIR="openwrt"
FILES_DIR="../files"
SCRIPTS_DIR="../scripts"

echo "==> Step 1: Update feeds"
if [ ! -d "$OPENWRT_DIR" ]; then
    echo "ERROR: $OPENWRT_DIR directory not found!"
    echo "Run: git clone --depth=1 --branch v25.12.5 https://github.com/openwrt/openwrt.git"
    exit 1
fi

cd "$OPENWRT_DIR"
./scripts/feeds update -a
./scripts/feeds install -a

echo "==> Step 2: Prepare build (config)"
chmod +x "$SCRIPTS_DIR"/*.sh
"$SCRIPTS_DIR"/prepare.sh

echo "==> Step 3: Copy custom files"
mkdir -p files
cp -a "$FILES_DIR"/. files/

echo "==> Step 4: Optimize"
"$SCRIPTS_DIR"/optimize.sh

echo "==> Step 5: Verify config (optional)"
if [ -f "./scripts/diffconfig.sh" ]; then
    ./scripts/diffconfig.sh > diffconfig.txt
    echo "==> Config saved to diffconfig.txt"
fi

echo "==> Step 6: Download sources"
make download -j"$(nproc)"

echo "==> Step 7: Build firmware"
make -j"$(nproc)" V=s

echo "==> Build complete!"
echo "Firmware location: bin/targets/"