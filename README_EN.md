[中文](README.md)

# ZTE ZXHN E2631 (ZX279128S) mainline Linux port

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

```
images/uImage-e2631.img    bootable kernel (initramfs embedded)
configs/zx279128s_e2631_defconfig     minimal defconfig
configs/zx279128s_e2631_full.config   full .config of the verified build
dts/zx279128s-e2631.dts    board device tree (+ compiled .dtb)
patches/                   changes on top of cnjn's 6.18.38 tree
initramfs/                 init.c + cpio packer (interactive bring-up shell)
tools/                     tftpd2.py (TFTP server), pack_uimage.py,
                           serial_ctl.py (UART driver), build scripts
docs/                      additional notes
```

## Building

Base tree: cnjn's `linux-mainline-zte-zxslc-sr1010` branch
`codex/sr1010-mainline` (Linux 6.18.38 + ZX279133 platform support),
then apply `patches/`, use `configs/zx279128s_e2631_defconfig`.

Works on Windows (MSYS2 + Arm GNU Toolchain mingw host) and Linux.
On Windows: `make -j4` maximum (higher -j is unstable under MSYS2),
`-marm` is forced in arch/arm/Makefile (the mingw toolchain defaults
to Thumb), fixdep/gen_init_cpio carry CRLF-compat patches.

## Known gaps / next steps

- Wired network: integrated GEPHY + zx279128s-mdio + TM/NPP/PP packet
  engine drivers not ported (reverse-engineer from vendor tm.ko/switch.ko)
- SPI-NAND (ZTE SPIFC) not ported → no flash access yet
- PCIe host (zte,ZX279127-pcie) not ported → MT7916 WiFi dormant
  (mt7916e driver is already built into the kernel)
- Single CPU for now: vendor `zte,zx279128-smp` enable-method not ported
- Clock tree uses fixed-clock placeholders (A9 PERIPHCLK 500MHz works)

## Getting started (for maintainers)

Three build paths, pick one:

| Method | Command | Applies to |
|---|---|---|
| **Linux / WSL2** | `./build.sh` | recommended, fully automatic |
| **Windows native** | `build.bat` | auto-installs MSYS2 + toolchain, slower |
| **GitHub Actions** | fork and push | zero setup, download uImage from Actions |

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
| mihomo kernel features | ✅ all built-in | TUN / TPROXY / xt_socket / nftables / conntrack / NAT / REDIRECT / MARK / policy routing / IPv6 / zram; TPROXY verified present in `/proc/net/ip_tables_targets` |
| On-board network tools | ✅ working | vendor ip / iptables / ip6tables / ebtables / tc / dnsmasq / curl packed into the initramfs |
| Device tree | ✅ done | CPU / GIC / PL310 / global timer / both UARTs; NAND, SPIFC, PCIe, MDIO, GEPHY nodes described but disabled |

### In progress / planned

| Item | Status | Notes |
|---|---|---|
| **Wired network driver** | ❌ not started (next target) | Three parts: GEPHY (4x 1G PHY), `zx279128s-mdio` controller, TM/NPP/PP packet engine. Reference: reverse-engineer vendor `tm.ko` (1.2MB) / `switch.ko` (223KB); cnjn ZX279133 MDIO patch (0008) as a style reference |
| Second core (SMP) | ❌ not ported | vendor enable-method `zte,zx279128-smp`; need to reverse the core-release sequence |
| SPI-NAND + transparent decrypt | ❌ not ported | ZTE SPIFC controller + Denali NAND; partitions are AES-128-ECB encrypted with a `zte_token`-derived key |
| PCIe host | ❌ not ported | `zte,ZX279127-pcie`; mt7916e is already built in, WiFi (MT7916) works once PCIe host lands |
| Clock tree | ⚠️ placeholder | topcrm/lsp0crpm/lsp1crpm modelled as fixed-clocks; A9 PERIPHCLK 500MHz works, peripheral clocks not individually calibrated |
| DW MMC | ⚠️ DT only | SD controller was disabled in the vendor DT too |
| USB host | ⚠️ kernel-side verified | dwc2/dwc3 drivers work; this model has no external USB port and the controller clock is unconnected, so DT keeps it disabled |

### Toolchain notes

- UART needs `earlycon=zteuart,0x94404000` (standard `earlycon=pl011` hits wrong registers → silence after "Starting kernel ...")
- Load address must be far from both 0x40008000 and 0x42000000 (0x43000000 proven reliable); loading at the entry address itself triggers the bootm XIP silent crash
- Cross-build: Windows via MSYS2 + Arm GNU Toolchain (mingw host), `-j4` max; Linux/WSL is faster
- Userland binaries must be armv5 soft-float (zig `arm-linux-musleabi` static, or vendor uClibc dynamic)

## Credits

- [cnjn](https://github.com/cnjn/linux-mainline-zte-zxslc-sr1010) —
  ZX279133 mainline patches, ZTE UART reverse engineering (register
  offsets, periphid, earlycon). The E2631 UART is the same IP.
- [1234205a/zte-sr1010-research](https://github.com/1234205a/zte-sr1010-research)
  — vendor firmware analysis methodology.
- Vendor kernels embed `zte_token`-derived AES keys for flash partitions;
  this port does not touch flash and contains no vendor keys.

## License

Kernel code: GPL-2.0 (see Linux tree). Port-specific files: GPL-2.0.
