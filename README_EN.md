# ZTE ZXHN E2631 (ZX279128S) mainline Linux port

[中文](README.md)

Mainline Linux 6.18.38 running on the ZTE ZXHN E2631 "巡天AX3000" router
(SoC: ZTE ZX279128S, dual Cortex-A9 @1GHz, 256MB DDR3, 128MB SPI NAND).

**Status: boots to an interactive busybox shell over UART. Verified on hardware.**

```
=== E2631 mainline bring-up init reached userspace ===
[init] kernel booted, zteuart console OK
[init] Features : half thumb fastmult edsp thumbee tls
[init] handing console to busybox shell
/ # iptables -t mangle -L PREROUTING    # works
/ # ip rule add fwmark 1 lookup 100     # works
/ # busybox cat /proc/net/ip_tables_targets
...
TPROXY
TPROXY
MASQUERADE
REDIRECT
...
```

## Hardware facts (verified)

| Item | Value |
|---|---|
| SoC | ZTE ZX279128S, dual Cortex-A9 rev 1 @1GHz |
| CPU features | `half thumb fastmult edsp thumbee tls` — **no VFP, no NEON, no hardware idiv** |
| RAM | 256MB DDR3-1333 (U-Boot reports 256MiB; DT says 128MB, adjust as needed) |
| NAND | 128MB SPI NAND (AMD/Spansion HYF1GQ4UTACAE) |
| UART | 0x94404000, **ZTE-custom PL011 register layout** (`zteuart` earlycon, periphid 0x001feffe) |
| Userland | must be **armv5 soft-float** (vendor used uClibc 0.9.33.2) |

## Kernel features for mihomo (all built-in =y, verified in image)

TUN, TPROXY (xt_TPROXY + nf_tproxy v4/v6), xt_socket, nftables
(nft_tproxy/nft_socket/nft_compat), iptables-legacy, conntrack, NAT,
REDIRECT/MASQUERADE/MARK, policy routing (ip rule fwmark), IPv6, zram,
overlayfs, ext4/squashfs/vfat.

mihomo binary: use the official `mihomo-linux-armv5` package (soft-float).

## Boot (TFTP, no flash writes)

Enter U-Boot boot mode: press `1` immediately at power-on, password
`5cE080@fyBD`, then Enter to stop autoboot.

```
setenv ipaddr 192.168.10.66
setenv serverip 192.168.1.100        # your PC running a TFTP server
tftp 0x43000000 uImage-e2631.img
bootm 0x43000000
```

**Important**: load the image at 0x43000000 (or any address far from
0x40008000 and the 0x42000000 region). `bootm` copies it to 0x40008000.
Loading AT 0x40008000 takes the XIP path and leaves the 64-byte uImage
header on the kernel entry point → silent crash.

## Repo layout

This repository **is the full Linux kernel source tree** (Linux 6.18.38 +
all E2631 platform changes committed in-tree). Clone and build directly -
no base tree fetch, no patches to apply.

```
arch/arm/boot/dts/zte/zx279128s-e2631.dts   board device tree (incl. zte/ Makefile)
arch/arm/configs/zx279128s_e2631_defconfig  minimal defconfig (initramfs embedded)
initramfs-e2631.cpio.gz                     embedded initramfs (busybox + uClibc + init)
e2631-tools/                                companion tools
│  tftpd2.py           minimal TFTP server (UDP 69)
│  pack_uimage.py      uImage packer (load/entry 0x40008000)
│  serial_ctl.py       UART driver for driving U-Boot
│  bootflow2.py        scripted tftp+bootm serial sequence
│  mkconfig.sh / cleanbuild3.sh / mihomobuild.sh    MSYS2 build steps
│  initramfs-src/      init.c + pack2.py (initramfs build source)
upstream-series/       cnjn's ZX279133 16-patch series (6.18.38 baseline, reference)
research.md            kernel-version research notes
README / README.md / README_EN.md
build.sh / build.bat   one-command build scripts (Linux/WSL and Windows/MSYS2)
.github/workflows/build.yml    CI: build on main and v* tags, publish Release
```

Built images are not committed; CI publishes them to GitHub Releases
(tag `v0.1.1` already ships `uImage-e2631.img`, ready to download and boot).

## Building

Clone and build in-tree. The commands below are exactly what CI runs
(no patches needed).

Linux / WSL (install Arm GNU Toolchain 10.3 first, add `bin` to PATH):

```bash
make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf- zx279128s_e2631_defconfig

make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf- -j$(nproc) zImage

make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf- zte/zx279128s-e2631.dtb

cat arch/arm/boot/zImage arch/arm/boot/dts/zte/zx279128s-e2631.dtb > zImage-dtb-e2631

python3 e2631-tools/pack_uimage.py zImage-dtb-e2631 uImage-e2631.img
```

Boot the resulting `uImage-e2631.img` via TFTP as described above.

Windows (MSYS2 + Arm GNU Toolchain mingw host) runs the same commands, note:

- `make -j4` maximum (higher `-j` is unstable under MSYS2);
- `-marm` is forced in arch/arm/Makefile (the mingw toolchain defaults to Thumb);
- fixdep/gen_init_cpio carry CRLF-compat patches.

Or just use GitHub Actions: fork and push (or `workflow_dispatch`) - the
image lands in the Actions page / Releases, zero local setup.

## Getting started (for maintainers)

Three build paths, pick one:

| Method | Command | Applies to |
|---|---|---|
| **Linux / WSL2** | `./build.sh` | recommended, one-command in-tree build |
| **Windows native** | `build.bat` | auto-installs MSYS2 + toolchain, slower on first run |
| **GitHub Actions** | fork and push | zero setup, download uImage from Actions / Releases |

Flash via TFTP: `tftp 0x43000000 uImage-e2631.img` then
`bootm 0x43000000` (the load address must be 0x43000000, see notes below).

## Porting status (2026-08-31)

### Done / verified

| Item | Status | Notes |
|---|---|---|
| Mainline 6.18.38 boot | ✅ done | U-Boot → kernel → userspace, full chain |
| ZTE custom UART | ✅ done | `zteuart` earlycon + ttyAMA0/1 console (register layout shared with ZX279133) |
| Interactive shell | ✅ done | vendor busybox v1.17.2 (soft-float) with working keyboard input |
| L2C-310 / GIC / global timer | ✅ done | single core, 1000 BogoMIPS |
| mihomo kernel features | ✅ all built-in | TUN/TPROXY/xt_socket/nftables/conntrack/NAT/REDIRECT/MARK/policy routing/IPv6/zram; TPROXY verified in `/proc/net/ip_tables_targets` |
| On-board network tools | ✅ available | vendor ip/iptables/ip6tables/ebtables/tc/dnsmasq/curl packed into initramfs |
| Device tree | ✅ done | CPU/GIC/PL310/global timer/dual UART; NAND, SPIFC, PCIe, MDIO, GEPHY nodes described but disabled |

### In progress / planned

| Item | Status | Notes |
|---|---|---|
| **Wired network driver** | ❌ not started (next goal) | GEPHY (4x 1G PHY) + `zx279128s-mdio` controller + TM/NPP/PP packet engine. Reference: reverse-engineer vendor `tm.ko` (1.2MB)/`switch.ko` (223KB); cnjn's ZX279133 MDIO patch (0008) is a controller template |
| Second core SMP | ❌ not ported | vendor enable-method `zte,zx279128-smp`; needs reverse engineering (likely A9 NDPGFCR/freeze registers) |
| SPI-NAND + transparent decrypt | ❌ not ported | ZTE SPIFC controller + Denali NAND; flash partitions use AES-128-ECB transparent decrypt (key derived from `zte_token`) |
| PCIe host | ❌ not ported | `zte,ZX279127-pcie`; mt7916e driver is already built in - WiFi (MT7916) works once PCIe is up |
| Clock tree | ⚠️ placeholder | topcrm/lsp0crpm/lsp1crpm are fixed-clocks; A9 PERIPHCLK 500MHz verified, peripheral clocks not individually calibrated |
| DW MMC | ⚠️ DT only | SD controller is disabled in the vendor DT as well |
| USB host | ⚠️ kernel support verified | dwc2/dwc3 work, but this board has no external USB port and controller clocks are unwired; kept disabled in DT |

### Debug toolchain notes

- UART must use `earlycon=zteuart,0x94404000` (standard `earlycon=pl011` hits wrong registers → silent hang after "Starting kernel ...")
- Load address must stay away from 0x40008000 and 0x42000000 (`0x43000000` is proven reliable); loading at the entry address itself triggers the bootm XIP-path silent crash
- Cross-compile: Windows uses MSYS2 + Arm GNU Toolchain (mingw host), `-j4` max; Linux/WSL is faster
- All userland binaries must be armv5 soft-float (zig `arm-linux-musleabi` static, or vendor uClibc dynamic)

## Acknowledgements

- [cnjn](https://github.com/cnjn/linux-mainline-zte-zxslc-sr1010) —
  ZX279133 mainline patches, ZTE UART reverse engineering (register offsets,
  periphid, earlycon). E2631 shares the same UART IP generation.
- [1234205a/zte-sr1010-research](https://github.com/1234205a/zte-sr1010-research)
  — vendor firmware analysis methodology.
- The vendor flash-partition AES key is derived from `zte_token`; this port
  does not touch flash and contains no vendor keys.

## License

Kernel code: GPL-2.0 (see the Linux source tree). Port-specific files: GPL-2.0.
