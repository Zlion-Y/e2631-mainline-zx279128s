#!/usr/bin/env bash
# One-command build for the ZTE ZXHN E2631 (ZX279128S) mainline kernel.
#
# Usage:
#   ./build.sh              # full: fetch base tree, patch, configure, build, pack
#   ./build.sh --no-fetch   # reuse existing ./linux tree
#
# Requirements:
#   Linux (or WSL2): gcc aarch64/arm cross or the Arm GNU Toolchain,
#   bc flex bison libssl-dev cpio wget git python3
#
# Output: out/uImage-e2631.img  (tftp 0x43000000 + bootm 0x43000000)
set -euo pipefail

BASE_REPO="https://github.com/cnjn/linux-mainline-zte-zxslc-sr1010"
BASE_BRANCH="codex/sr1010-mainline"     # Linux 6.18.38 + ZX279133 support
DEFCONFIG=zx279128s_e2631_defconfig
ROOT="$(cd "$(dirname "$0")" && pwd)"
LINUX="$ROOT/linux"
OUT="$ROOT/out"
ARCH=arm
JOBS=$(nproc)

echo "==> [1/5] base tree"
if [ "${1:-}" != "--no-fetch" ]; then
    if [ ! -f "$LINUX/Makefile" ]; then
        git clone --depth 1 -b "$BASE_BRANCH" "$BASE_REPO" "$LINUX"
    fi
fi
cd "$LINUX"

echo "==> [2/5] patches"
# idempotent: only apply if the DTS is absent
if [ ! -f arch/arm/boot/dts/zte/zx279128s-e2631.dts ]; then
    git apply "$ROOT"/patches/*.patch
    echo "    patches applied"
else
    echo "    already patched, skipping"
fi

echo "==> [3/5] config"
# make the zte DTS dir build
if ! grep -q "subdir-y += zte" arch/arm/boot/dts/Makefile; then
    printf 'subdir-y += zte\n' >> arch/arm/boot/dts/Makefile
fi
cp "$ROOT/configs/$DEFCONFIG" arch/arm/configs/
make ARCH=$ARCH O="$ROOT/build" "$DEFCONFIG"

echo "==> [4/5] build (-j$JOBS)"
make ARCH=$ARCH O="$ROOT/build" -j"$JOBS" zImage
make ARCH=$ARCH O="$ROOT/build" dtbs || true
DTB=$(find "$ROOT/build/arch/arm/boot/dts" -name 'zx279128s-e2631.dtb' | head -1)
[ -n "$DTB" ] || { echo "ERROR: dtb not built"; exit 1; }

echo "==> [5/5] pack uImage"
mkdir -p "$OUT"
cat "$ROOT/build/arch/arm/boot/zImage" "$DTB" > "$OUT/zImage-dtb-e2631"
python3 "$ROOT/tools/pack_uimage.py" "$OUT/zImage-dtb-e2631" "$OUT/uImage-e2631.img"

cat <<EOF

========================================================
 Build complete: $OUT/uImage-e2631.img

 Boot on the board (U-Boot):
   setenv ipaddr 192.168.10.66
   setenv serverip <your PC IP>
   tftp 0x43000000 uImage-e2631.img
   bootm 0x43000000

 Load address MUST be far from 0x40008000 (XIP trap) and
 the 0x42000000 region (U-Boot self-use, large tftp fails).
========================================================
EOF
