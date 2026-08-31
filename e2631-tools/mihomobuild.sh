#!/bin/bash
export PATH="/usr/bin:/d/Work/e2631-kernel/tc/gcc-arm-10.3-2021.07-mingw-w64-i686-arm-none-linux-gnueabihf/bin:$PATH"
cd /d/Work/e2631-kernel/sr1010-kernel
M="make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf-"
$M -j4 zImage > /d/Work/e2631-kernel/build.log 2>&1
echo ZEXIT=$?
tail -3 /d/Work/e2631-kernel/build.log | grep -vE "shared_info|^      [01] .main."
for i in 1 2 3 4 5; do powershell -NoProfile -Command "[console]::beep(1000,300)" 2>/dev/null; sleep 0.2; done
