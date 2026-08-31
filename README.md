[English](README_EN.md)

# ZTE ZXHN E2631（ZX279128S）主线 Linux 移植

主线 Linux 6.18.38 跑在中兴 ZXHN E2631（巡天AX3000）路由器上。
SoC：ZTE ZX279128S，双核 Cortex-A9 @1GHz，256MB DDR3，128MB SPI NAND。

**状态：已在真机上启动到交互式 busybox shell，全部验证通过。**

```
=== E2631 mainline bring-up init reached userspace ===
[init] kernel booted, zteuart console OK
[init] Features : half thumb fastmult edsp thumbee tls
[init] handing console to busybox shell
/ # iptables -t mangle -L PREROUTING    # 正常
/ # ip rule add fwmark 1 lookup 100     # 正常
/ # busybox cat /proc/net/ip_tables_targets
...
TPROXY
TPROXY
MASQUERADE
REDIRECT
...
```

## 硬件结论（已实测）

| 项目 | 结论 |
|---|---|
| SoC | ZTE ZX279128S，双核 Cortex-A9 rev 1 @1GHz |
| CPU 特性 | `half thumb fastmult edsp thumbee tls` — **无 VFP、无 NEON、无硬件除法** |
| 内存 | 256MB DDR3-1333（U-Boot 报 256MiB；DT 里写的 128MB，可按需调整） |
| NAND | 128MB SPI NAND（AMD/Spansion HYF1GQ4UTACAE） |
| 串口 | 0x94404000，**ZTE 定制 PL011 寄存器布局**（earlycon 用 `zteuart`，periphid 0x001feffe） |
| 用户态 | 必须用 **armv5 软浮点**（原厂 uClibc 0.9.33.2） |

## mihomo 所需内核特性（全部内建 =y，已在镜像中验证符号）

TUN、TPROXY（xt_TPROXY + nf_tproxy v4/v6）、xt_socket、nftables
（nft_tproxy / nft_socket / nft_compat）、iptables-legacy、conntrack、NAT、
REDIRECT / MASQUERADE / MARK、策略路由（ip rule fwmark）、IPv6、zram、
overlayfs、ext4 / squashfs / vfat。

mihomo 二进制：请使用官方 `mihomo-linux-armv5` 包（软浮点）。

## 启动方法（TFTP，不写 flash）

进入 U-Boot boot 模式：上电瞬间按 `1`，输入密码 `5cE080@fyBD`，
再按回车拦住 autoboot。

```
setenv ipaddr 192.168.10.66
setenv serverip 192.168.1.100        # 你电脑上跑 TFTP 服务器的地址
tftp 0x43000000 uImage-e2631.img
bootm 0x43000000
```

**重要**：镜像必须加载到 0x43000000（或任何远离 0x40008000 和 0x42000000
区域的地址）。`bootm` 会自动把镜像搬运到 0x40008000。如果直接加载到
0x40008000 会走 XIP 路径，64 字节的 uImage 头会压在内核入口上 → 静默崩溃。

## 仓库结构

```
images/uImage-e2631.img    可启动内核（initramfs 已内嵌）
configs/zx279128s_e2631_defconfig     精简 defconfig
configs/zx279128s_e2631_full.config   验证过的完整 .config
dts/zx279128s-e2631.dts    板级设备树（含编译好的 .dtb）
patches/                   基于 cnjn 6.18.38 树的修改补丁
initramfs/                 init.c + cpio 打包器（交互式 bring-up shell）
tools/                     tftpd2.py（TFTP 服务器）、pack_uimage.py、
                           serial_ctl.py（串口驱动）、构建脚本
docs/                      调试过程存档
```

## 编译

基础源码树：cnjn 的 `linux-mainline-zte-zxslc-sr1010` 仓库
`codex/sr1010-mainline` 分支（Linux 6.18.38 + ZX279133 平台支持），
套用 `patches/`，使用 `configs/zx279128s_e2631_defconfig`。

Windows（MSYS2 + Arm GNU Toolchain mingw 宿主）和 Linux 都能编。
Windows 注意：`make -j4` 上限（更高 -j 在 MSYS2 下不稳定）；
arch/arm/Makefile 里已强制 `-marm`（mingw 工具链默认 Thumb）；
fixdep / gen_init_cpio 带了 CRLF 兼容补丁。

## 已知缺口 / 后续计划

- 有线网络：集成 GEPHY + zx279128s-mdio + TM/NPP/PP 包处理引擎驱动未移植
  （需从原厂 tm.ko / switch.ko 逆向）
- SPI-NAND（ZTE SPIFC）未移植 → 暂无法访问 flash
- PCIe host（zte,ZX279127-pcie）未移植 → MT7916 WiFi 暂不可用
  （mt7916e 驱动已编入内核，等 PCIe host 驱动）
- 目前单核：原厂 `zte,zx279128-smp` enable-method 未移植
- 时钟树用 fixed-clock 占位（A9 PERIPHCLK 500MHz 实测可用）

## 快速开始（接手者必读）

三种编译方式，任选其一：

| 方式 | 命令 | 适用 |
|---|---|---|
| **Linux / WSL2** | `./build.sh` | 推荐，全自动（拉依赖→补丁→编译→打包） |
| **Windows 原生** | `build.bat` | 自动装 MSYS2+工具链后编译（较慢） |
| **GitHub Actions** | fork 后 push 即可 | 零环境，云端编译，Actions 页面下载 uImage |

产物 `uImage-e2631.img` 用 TFTP 刷入：`tftp 0x43000000 uImage-e2631.img`，
然后 `bootm 0x43000000`（加载地址必须是 0x43000000，见下方说明）。

## 适配进度（2026-08-31）

### 已完成 / 已验证

| 项目 | 状态 | 说明 |
|---|---|---|
| 主线内核 6.18.38 启动 | ✅ 完成 | U-Boot → 内核 → 用户空间全链路 |
| ZTE 定制串口 | ✅ 完成 | `zteuart` earlycon + ttyAMA0/1 控制台（寄存器布局同 ZX279133） |
| 交互式 shell | ✅ 完成 | 原厂 busybox v1.17.2（软浮点）+ 键盘输入 |
| L2C-310 / GIC / 全局定时器 | ✅ 完成 | 单核 1000 BogoMIPS |
| mihomo 内核特性 | ✅ 全部内建 | TUN / TPROXY / xt_socket / nftables / conntrack / NAT / REDIRECT / MARK / 策略路由 / IPv6 / zram，已实测 TPROXY 注册于 `/proc/net/ip_tables_targets` |
| 板上网络命令 | ✅ 可用 | 原厂 ip / iptables / ip6tables / ebtables / tc / dnsmasq / curl 已打包进 initramfs |
| 设备树 | ✅ 完成 | CPU / GIC / PL310 / 全局定时器 / 双串口；NAND、SPIFC、PCIe、MDIO、GEPHY 节点已描述未启用 |

### 进行中 / 计划

| 项目 | 状态 | 说明 |
|---|---|---|
| **有线网络驱动** | ❌ 未开始（下一个目标） | 三件套：GEPHY（4 个 1G PHY）、`zx279128s-mdio` 控制器、TM/NPP/PP 包处理引擎。参考：原厂 `tm.ko`（1.2MB）/`switch.ko`（223KB）逆向，cnjn 的 ZX279133 MDIO 补丁（0008）可作控制器写法参考 |
| 第二核 SMP | ❌ 未移植 | 原厂 enable-method `zte,zx279128-smp`，需逆向上核流程（推测类似 A9 的 NDPGFCR/freeze 寄存器） |
| SPI-NAND + 透明解密 | ❌ 未移植 | ZTE SPIFC 控制器 + Denali NAND；flash 分区带 AES-128-ECB 透明解密（密钥由 `zte_token` 派生，型号字符串进内核后可推导） |
| PCIe host | ❌ 未移植 | `zte,ZX279127-pcie`；mt7916e 驱动已编入内核，PCIe 通了 WiFi 即可用（MT7916） |
| 时钟树 | ⚠️ 占位 | topcrm/lsp0crpm/lsp1crpm 用 fixed-clock 代替；A9 PERIPHCLK 500MHz 实测工作，外设时钟精度未逐一校准 |
| DW MMC | ⚠️ DT 已写 | SD 控制器在原厂 DT 里就是 disabled |
| USB host | ⚠️ 内核支持已验证 | dwc2/dwc3 驱动正常，但本机型无对外 USB 口，且控制器时钟未接，DT 里保持禁用 |

### 调试工具链备忘

- 串口必须用 `earlycon=zteuart,0x94404000`（标准 `earlycon=pl011` 会打到错误寄存器，表现为 "Starting kernel ..." 后静默）
- 内核加载地址必须远离 0x40008000 和 0x42000000（实测 `0x43000000` 可靠）；加载到入口地址本身会触发 bootm XIP 路径静默崩溃
- 交叉编译：Windows 用 MSYS2 + Arm GNU Toolchain（mingw 宿主），`-j4` 上限；Linux/WSL 更快
- 用户态二进制一律 armv5 软浮点（zig `arm-linux-musleabi` 静态编译，或原厂 uClibc 动态库）

## 致谢

- [cnjn](https://github.com/cnjn/linux-mainline-zte-zxslc-sr1010) —
  ZX279133 主线补丁、ZTE UART 逆向（寄存器偏移、periphid、earlycon）。
  E2631 的 UART 是同代 IP，直接受益。
- [1234205a/zte-sr1010-research](https://github.com/1234205a/zte-sr1010-research)
  — 原厂固件分析方法论。
- 原厂内核的 flash 分区 AES 密钥由 `zte_token` 派生；本移植不碰 flash，
  不包含任何原厂密钥。

## 许可证

内核代码：GPL-2.0（见 Linux 源码树）。移植专属文件：GPL-2.0。
