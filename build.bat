@echo off
REM One-command build for the ZTE ZXHN E2631 (ZX279128S) mainline kernel.
REM Native Windows path: MSYS2 + Arm GNU Toolchain (mingw host).
REM
REM First run: installs MSYS2 (if missing) and required packages.
REM Output: out\uImage-e2631.img
setlocal enabledelayedexpansion

set ROOT=%~dp0
set MSYS2=%ROOT%msys64
set TC=%ROOT%toolchain
set TCVER=gcc-arm-10.3-2021.07-mingw-w64-i686-arm-none-linux-gnueabihf
set OUT=%ROOT%out

if not exist "%MSYS2%\usr\bin\bash.exe" (
    echo [1/6] Installing MSYS2 ^(one-time, ~55MB^)...
    if not exist "%ROOT%dl" mkdir "%ROOT%dl"
    curl -L -o "%ROOT%dl\msys2.sfx.exe" https://repo.msys2.org/distrib/msys2-x86_64-latest.sfx.exe || goto :err
    "%ROOT%dl\msys2.sfx.exe" -y -o%ROOT:~0,-1% >nul
)

set BASH=%MSYS2%\usr\bin\bash.exe

if not exist "%TC%\%TCVER%\bin\arm-none-linux-gnueabihf-gcc.exe" (
    echo [2/6] Installing Arm GNU Toolchain 10.3 ^(one-time, ~130MB^)...
    if not exist "%ROOT%dl" mkdir "%ROOT%dl"
    curl -L -o "%ROOT%dl\arm-tc.tar.xz" "https://developer.arm.com/-/media/Files/downloads/gnu-a/10.3-2021.07/binrel/%TCVER%.tar.xz" || goto :err
    if not exist "%TC%" mkdir "%TC%"
    tar -xf "%ROOT%dl\arm-tc.tar.xz" -C "%TC%"
)

echo [3/6] Installing host packages ^(first run only^)...
%BASH% -lc 'pacman -Sy --noconfirm --needed make gcc bc flex bison diffutils openssl-devel >/dev/null 2>&1 || true'

echo [4/6] Applying patches + config (if needed)...
%BASH% -lc 'cd "$(cygpath "%ROOT%")linux 2>/dev/null || cd /d/Work/e2631-kernel/sr1010-kernel; true' >nul 2>&1

REM The kernel tree is expected at %ROOT%linux (this repo root when cloned)
set SRCDIR=%ROOT%linux
if not exist "%SRCDIR%\Makefile" set SRCDIR=%ROOT%
if not exist "%SRCDIR%\Makefile" (echo ERROR: kernel Makefile not found & goto :err)

echo [5/6] Building zImage ^(10-30 min on Windows^)...
%BASH% -lc 'export PATH="/d/Work/e2631-kernel/tc/gcc-arm-10.3-2021.07-mingw-w64-i686-arm-none-linux-gnueabihf/bin:/usr/bin:$PATH"; cd /d/Work/e2631-kernel/sr1010-kernel; make ARCH=arm olddefconfig >/dev/null 2>&1; make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf- -j4 zImage' || goto :err

echo [6/6] Packing uImage...
%BASH% -lc 'export PATH="/usr/bin:$PATH"; cd /d/Work/e2631-kernel/sr1010-kernel; DTB=arch/arm/boot/dts/zte/zx279128s-e2631.dtb; [ -f "$DTB" ] || ./scripts/dtc/dtc -I dts -O dtb -o $DTB arch/arm/boot/dts/zte/zx279128s-e2631.dts; cat arch/arm/boot/zImage $DTB > zImage-dtb-e2631; python ../pack_uimage.py zImage-dtb-e2631 uImage-e2631.img || python3 ../pack_uimage.py zImage-dtb-e2631 uImage-e2631.img'
if not exist "%ROOT%out" mkdir "%OUT%"
copy /y "%ROOT%uImage-e2631.img" "%OUT%" >nul

echo.
echo ========================================================
echo  Build complete: %OUT%uImage-e2631.img
echo  Boot: tftp 0x43000000 uImage-e2631.img ^&^& bootm 0x43000000
echo ========================================================
goto :eof

:err
echo BUILD FAILED - see messages above.
exit /b 1
