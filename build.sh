#!/usr/bin/env bash
# One-command in-tree build for the ZTE ZXHN E2631 (ZX279128S) mainline kernel.
#
# The repository root IS the full kernel source tree (Linux 6.18.38 + E2631
# platform support). No base tree fetch, no patches - clone, build, boot.
#
# Usage:
#   ./build.sh
#
# Requirements (Linux / WSL2):
#   Arm GNU Toolchain 10.3 (arm-none-linux-gnueabihf-) in PATH, or export
#   CROSS_COMPILE=<your-prefix->
#   host packages: bc flex bison libssl-dev cpio python3
#
# Output: out/uImage-e2631.img  (tftp 0x43000000 + bootm 0x43000000)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

CROSS="${CROSS_COMPILE:-arm-none-linux-gnueabihf-}"
DEFCONFIG=zx279128s_e2631_defconfig
DTB=arch/arm/boot/dts/zte/zx279128s-e2631.dtb
OUT="$ROOT/out"
JOBS="$(nproc)"

if [ ! -f "arch/arm/configs/$DEFCONFIG" ]; then
    echo "ERROR: $DEFCONFIG not found - run this from the cloned repo root" >&2
    exit 1
fi

echo "==> [1/4] configure ($DEFCONFIG)"
make ARCH=arm CROSS_COMPILE="$CROSS" "$DEFCONFIG"

echo "==> [2/4] build zImage (-j$JOBS)"
make ARCH=arm CROSS_COMPILE="$CROSS" -j"$JOBS" zImage

echo "==> [3/4] build dtb"
make ARCH=arm CROSS_COMPILE="$CROSS" zte/zx279128s-e2631.dtb
[ -f "$DTB" ] || { echo "ERROR: $DTB not built" >&2; exit 1; }

echo "==> [4/4] pack uImage"
mkdir -p "$OUT"
cat arch/arm/boot/zImage "$DTB" > "$OUT/zImage-dtb-e2631"
python3 "$ROOT/e2631-tools/pack_uimage.py" "$OUT/zImage-dtb-e2631" "$OUT/uImage-e2631.img"

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
