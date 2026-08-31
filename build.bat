@echo off
REM One-command in-tree build for the ZTE ZXHN E2631 (ZX279128S) mainline kernel.
REM Native Windows path: MSYS2 + Arm GNU Toolchain (mingw host).
REM The repository root IS the full kernel source tree - no patches needed.
REM
REM First run: downloads MSYS2 and the Arm GNU Toolchain into
REM   %LOCALAPPDATA%\e2631-build   (outside the repo, reused on later runs)
REM Output: out\uImage-e2631.img
setlocal enabledelayedexpansion

set ROOT=%~dp0
if "%LOCALAPPDATA%"=="" (set ENVDIR=%USERPROFILE%\.e2631-build) else (set ENVDIR=%LOCALAPPDATA%\e2631-build)
set MSYS2=%ENVDIR%\msys64
set TC=%ENVDIR%\toolchain
set TCVER=gcc-arm-10.3-2021.07-mingw-w64-i686-arm-none-linux-gnueabihf
set OUT=%ROOT%out
set BASH=%MSYS2%\usr\bin\bash.exe
set SRCDIR=%ROOT:~0,-1%

if not exist "%SRCDIR%\Makefile" (echo ERROR: kernel Makefile not found - run this from the cloned repo root & goto :err)

if not exist "%BASH%" (
    echo [1/5] Installing MSYS2 into %ENVDIR% ^(one-time, ~55MB^)...
    if not exist "%ENVDIR%\dl" mkdir "%ENVDIR%\dl"
    curl -L -o "%ENVDIR%\dl\msys2.sfx.exe" https://repo.msys2.org/distrib/msys2-x86_64-latest.sfx.exe || goto :err
    "%ENVDIR%\dl\msys2.sfx.exe" -y -o"%ENVDIR%" >nul
)

if not exist "%TC%\%TCVER%\bin\arm-none-linux-gnueabihf-gcc.exe" (
    echo [2/5] Installing Arm GNU Toolchain 10.3 ^(one-time, ~130MB^)...
    if not exist "%ENVDIR%\dl" mkdir "%ENVDIR%\dl"
    curl -L -o "%ENVDIR%\dl\arm-tc.tar.xz" "https://developer.arm.com/-/media/Files/downloads/gnu-a/10.3-2021.07/binrel/%TCVER%.tar.xz" || goto :err
    if not exist "%TC%" mkdir "%TC%"
    tar -xf "%ENVDIR%\dl\arm-tc.tar.xz" -C "%TC%"
)

echo [3/5] Installing host packages ^(first run only^)...
%BASH% -lc 'pacman -Sy --noconfirm --needed make gcc bc flex bison diffutils openssl-devel python >/dev/null 2>&1 || true'

echo [4/5] Building zImage ^(-j4, 10-30 min on Windows^)...
%BASH% -lc 'cd "$(cygpath "%SRCDIR%")" && export PATH="$(cygpath "%TC%\%TCVER%\bin"):/usr/bin:$PATH" && make ARCH=arm zx279128s_e2631_defconfig && make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf- -j4 zImage' || goto :err

echo [5/5] Packing uImage...
%BASH% -lc 'cd "$(cygpath "%SRCDIR%")" && make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf- zte/zx279128s-e2631.dtb && mkdir -p "$(cygpath "%OUT%")" && cat arch/arm/boot/zImage arch/arm/boot/dts/zte/zx279128s-e2631.dtb > "$(cygpath "%OUT%\zImage-dtb-e2631")" && python3 "$(cygpath "%SRCDIR%\e2631-tools\pack_uimage.py")" "$(cygpath "%OUT%\zImage-dtb-e2631")" "$(cygpath "%OUT%\uImage-e2631.img")"' || goto :err

echo.
echo ========================================================
echo  Build complete: %OUT%\uImage-e2631.img
echo  Boot: tftp 0x43000000 uImage-e2631.img ^&^& bootm 0x43000000
echo  Do NOT load at 0x40008000 (XIP trap) or 0x42000000.
echo ========================================================
goto :eof

:err
echo BUILD FAILED - see messages above.
exit /b 1
