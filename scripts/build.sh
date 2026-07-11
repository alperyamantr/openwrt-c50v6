#!/bin/bash
set -e

echo "==> Preparing build"
./scripts/prepare.sh

echo "==> Copying custom files"
mkdir -p files
cp -a ../files/. files/

echo "==> Running optimizations"
./scripts/optimize.sh

echo "==> Downloading sources"
make download -j"$(nproc)"

echo "==> Building firmware"
make -j"$(nproc)"