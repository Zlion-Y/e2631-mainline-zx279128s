#!/bin/bash
export PATH="/usr/bin:/d/Work/e2631-kernel/tc/gcc-arm-10.3-2021.07-mingw-w64-i686-arm-none-linux-gnueabihf/bin:$PATH"
cd /d/Work/e2631-kernel/sr1010-kernel
M="make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf-"
$M drivers/of/built-in.a 2>&1 | tail -1
$M drivers/built-in.a 2>&1 | tail -1
$M -j4 zImage > /d/Work/e2631-kernel/build.log 2>&1
echo ZEXIT=$?
tail -3 /d/Work/e2631-kernel/build.log | grep -vE "shared_info|^      [01] .main."
ls -la arch/arm/boot/zImage 2>/dev/null
