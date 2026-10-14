# ZTE ZXHN E2631（ZX279128S）mainline Linux 端口

Linux 6.18.38 在 ZTE ZXHN E2631（SoC = ZTE ZX279128S，双核 Cortex-A9）上
能配置、能编译、能启动到交互 shell。本仓库就是这棵内核树，加上为这块板子构建所需的改动，
没有别的。

**这里不产可刷固件。** 要给这台机器刷的系统在 <https://github.com/Zlion-Y/zte-e2631-openwrt>：
OpenWrt 端口，产物是原厂升级包格式，可直接从原厂 `supgrade.html` 刷入，并且能从 OpenWrt
改 A/B 槽标记切回原系统 —— 两条都在真机验收过。本仓库只回答一个问题：
**mainline 能不能在这颗 SoC 上跑起来**，答案是能（见下面的启动记录）。

## 构建

只三条命令，产物是 `zImage` + 一块板子的 `.dtb`：

```bash
make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf- zx279128s_e2631_defconfig
make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf- -j$(nproc) zImage
make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf- dtbs
```

产物：`arch/arm/boot/zImage`、`arch/arm/boot/dts/zte/zx279128s-e2631.dtb`。

- 交叉编译器用 Arm GNU Toolchain 10.3-2021.07（`arm-none-linux-gnueabihf-`）。
  OpenWrt 的 `arm-openwrt-linux-muslgnueabi-` 同样能编 —— 内核自己跟 ABI 无关，
  软浮点这条约束只作用于**用户态**（见下表）。
- `dtbs` 只会造这一台机器的 dtb：`arch/arm/boot/dts/zte/` 是本树独有的目录，
  `subdir-y += zte` 是 2026-10-14 清理时才补进 `arch/arm/boot/dts/Makefile` 的，
  在那之前 `make dtbs` 根本不进这个目录（只能靠点名 `make zte/xxx.dtb`）。
- Windows/MSYS2 上同一套命令能跑，但 `-j` 到 4 就封顶（更高在 MSYS2 下不稳定），
  且 `arch/arm/Makefile` 里强制了 `-marm`（mingw 工具链默认 Thumb，会让这颗 A9 起不来）。
- 没有 CI：本仓库不自动构建，产物不发布 Release。

## 板子的硬件事实（全部实测，不是照着型号猜的）

| 项目 | 结论 |
|---|---|
| SoC | ZTE ZX279128S，2× Cortex-A9 rev 1（`CPU: ARMv7 Processor [414fc091]`）@1 GHz |
| FPU | **无 VFP、无 NEON、无硬件除法**：`Features: half thumb fastmult edsp thumbee tls` |
| 用户态 ABI | 必须 armv5 软浮点 EABI5（原厂是 uClibc 0.9.33.2 软浮点；mihomo 用官方 `linux-armv5` 包） |
| 内存 | 256 MiB DDR3-1333（U-Boot 报 256 MiB，原厂 DT `reg = <0x40000000 0x10000000>`，原厂 bootargs 带 `mem=256M`） |
| 闪存 | 128 MiB SPI-NAND（HYF1GQ4UTACAE），擦除块 128 KiB，片上 ECC |
| 串口 | `0x94404000` / `0x94405000`，ZTE 改版 PL011（寄存器偏移与 arm 版不同，periphid `0x001feffe`） |
| 中断/定时器 | Cortex-A9 GIC @`0x00801000`，全局定时器 @`0x00800200` |
| L2 | ARM PL310 @`0x00c00000` |
| 有线 | 1 WAN + 3 LAN，全走 SoC 内置 GPHY（MDIO @`0x9a101000`，GPHY @`0x9b000000`） |
| Wi-Fi | MT7916（PCIe `14c3:7906` + `14c3:790a`，跨两个 root port） |
| USB | **这台没有 USB 器件**：原厂硬件表 `/proc/capability/portinfo` 是 `usb:0`，原厂内核 `# CONFIG USB is not set` |

## 配置里那几条不能动的约束

改 `zx279128s_e2631_defconfig` 或 DTS 之前先读这段，每一条都是踩过之后写下来的。

- **软浮点是用户态的事，不是内核配置的事**：本 defconfig 保留 `CONFIG_VFP=y`，运行时探测不到就
  不启用，日志里那句 `VFP support v0.3: not present` 就是它在这块没有 VFP 的 A9 上的表现。
  真正必须一致的是交叉工具链与用户态二进制（`-mfloat-abi=soft`、不带 `-mfpu`，armv5 EABI5）；
  OpenWrt 那边之所以把 `CONFIG_VFP` 从内核配置里剥掉，是因为在那套构建里内核配置会牵着
  工具链的浮点 ABI 走，不是内核本身会崩。
- **USB 整条关掉**（`# CONFIG_USB_SUPPORT is not set`），DTS 里 `usb0`/`usb1` 也标了 `disabled`。
  探测一个不存在的控制器会挂住总线，然后看门狗把机器反复重启，表现出来像"刷完起不来"。
- **`CONFIG_CMDLINE_FORCE=y`**：内核命令行写死在 `CONFIG_CMDLINE`，DT 的 `chosen/bootargs`
  会被忽略。两处内容有意保持一致，改了记得都改。
- **串口必须 `earlycon=zteuart,0x94404000`**。用标准 `earlycon=pl011` 会打到错误的寄存器偏移，
  现象是 `Starting kernel ...` 之后彻底静默 —— 很容易被误判成内核没起来。
- **时钟是 `fixed-clock` 占位**（uart 25 MHz、APB 100 MHz、A9 PERIPHCLK 500 MHz）。
  PERIPHCLK 500 MHz 实测能工作；外设时钟精度没有逐个校准过。
- **只声明 `cpu@0`**：原厂 `enable-method = "zte,zx279128-smp"` 的上核流程没移植，
  单核跑（`smp: Brought up 1 node, 1 CPU`）。

## 本树相对上游 v6.18.38 改了什么

用 blob 哈希把整棵树跟 `gregkh/linux` 的 `v6.18.38` 逐个文件比过（91191 个上游文件），结果是
**改 6 个文件、加 4 个文件、上游文件一个不少**：

| 文件 | 改它的原因 |
|---|---|
| `drivers/tty/serial/amba-pl011.c` | ZTE 改版 PL011 的寄存器偏移表（`vendor_zte`，靠 `arm,primecell-periphid = <0x001feffe>` 命中）、`zteuart` earlycon（具名 + DT 两种形式）、以及该 vendor 才做的可选 shared-reset |
| `Documentation/devicetree/bindings/serial/pl011.yaml` | 上面那条 compatible 的 schema：要求 `arm,primecell-periphid`，不要求这块板子没有的 reset 提供者 |
| `arch/arm/Makefile` | `CFLAGS_ISA` 强制 `-marm`（去掉 `cc-option` 探测）：mingw 工具链默认产 Thumb，这颗 A9 起不来 |
| `scripts/basic/fixdep.c` | MinGW 交叉编译器会把 Windows 绝对路径（带盘符）写进 `.cmd` 依赖里，宿主端打不开；遇到这种条目跳过 CONFIG 解析而不是让构建失败 |
| `usr/gen_init_cpio.c` | MSYS 宿主没有 `copy_file_range()` / `O_LARGEFILE`，补一个本地实现 |
| `arch/arm/boot/dts/Makefile` | `subdir-y += zte`，让 `make dtbs` 真的进这块板子的目录 |

新增的 4 个文件就是这块板子本身：`arch/arm/boot/dts/zte/zx279128s-e2631.dts`、
`arch/arm/boot/dts/zte/Makefile`、`arch/arm/configs/zx279128s_e2631_defconfig`、这份 `README.md`。

> [!NOTE]
> 第 1、2、6 行是移植本身；第 3、4、5 行只是为了让 Windows 宿主也能编。只在 Linux 上构建的话
> 那三条没有意义，但也不碍事。

### 在 Windows 上 clone 会看到假象

内核里有一批只差大小写的同名文件（`net/netfilter/xt_DSCP.c` 与 `xt_dscp.c`、
`xt_CONNMARK.h` 与 `xt_connmark.h`、`ipt_TTL.h` 与 `ipt_ttl.h` 等 13 组）。Windows 的文件系统
分不出大小写，一块磁盘上只能落一份，所以 **checkout 出来的一定是残缺的**，`git status` 会长期把
另一份报成"已修改"。仓库里的内容是对的（哈希比过），但要构建请用 Linux/WSL，
或者 `git archive` 出一份 LF 树再编 —— 顺带说一句，CRLF 的工作副本 kconfig 直接解析失败：

```
Documentation/Kconfig:13: unknown statement "If"
```

这条曾经把两个不同 SoC 的文件内容互相覆盖掉（本仓库第一次提交时就发生了），已经在
"Give the case-colliding x_tables files their own content back" 那个提交里按上游 blob 修好。


## 移植进度

### 已经验证过（2026-08-31 上板）

| 项目 | 状态 | 证据 |
|---|---|---|
| 内核启动 | 完成 | 下面那份启动记录：`Booting Linux on physical CPU 0x0` → `Run /init as init process` |
| ZTE 定制串口 | 完成 | `earlycon: zteuart0 at MMIO 0x94404000` → `94404000.serial: ttyAMA0 ... is a PL011 rev1`，控制台交接后仍有交互 shell |
| GIC / 全局定时器 / PL310 | 完成 | 单核 1000 BogoMIPS，无 L2 报错 |
| 中断 | 完成 | shell 里 iptables / ip rule / TPROXY 全通（TPROXY 出现在 `/proc/net/ip_tables_targets`） |
| mihomo 需要的内核特性 | 全部内建 `=y` | TUN、TPROXY（`xt_TPROXY` + `nf_tproxy` v4/v6）、`xt_socket`、nftables（`nft_tproxy`/`nft_socket`/`nft_compat`）、iptables-legacy、conntrack、NAT、REDIRECT/MASQUERADE/MARK、策略路由、IPv6、zram、overlayfs、ext4/squashfs/vfat |

### 没做（这也是它停在"验证用端口"的原因）

| 项目 | 缺什么 |
|---|---|
| 有线网络 | 三件套都缺：GEPHY（4 个 1G PHY）、`zx279128s-mdio` 控制器、TM/NPP/PP 包处理引擎。DTS 里四个节点已描述但 `disabled`。**本机没有 `tm.ko` 可逆向**：E2631 的原厂配置是 `CONFIG_ZX_TM=y`（内建，镜像里的 vmlinux 无符号），带完整符号表的 `tm.ko`(1,240,916 B / 1,286 具名函数) 与 `switch.ko`(198,140 B / 214 具名函数) 来自同一颗 SoC 的另一块板（F670L），由 cubingmucus998 公开：见 issue #1 |
| 第二核 | 上核流程未逆向（`zte,zx279128-smp`） |
| SPI-NAND | `zte,ZX279127-spifc` 控制器 + Denali NAND 未接；原厂分区里 rootfs 是 AES-128-ECB 密文，解密是原厂内核的软件层，非原厂内核不需要它（OpenWrt 侧已按明文跑通） |
| PCIe host | `zte,ZX279127-pcie` 未移植 ⇒ MT7916 / Wi-Fi 在本树上用不上 |
| 时钟树 | topcrm / lsp0crpm / lsp1crpm 用 fixed-clock 代替，没有真正的时钟驱动 |

### 已知小毛病（不影响启动，先记下来）

- `GIC: PPI11 is secure or misconfigured` 会打印若干次：全局定时器用的 PPI11 在原厂固件下是安全组。
- `ttyAMA0 ... base_baud = 0`：波特率靠固定时钟推算，实测 115200 正常。

## 启动记录（实测，点击展开）

<details>
<summary>内核 6.18.38 → busybox shell 的关键日志（2026-08-31 上板，串口原文）</summary>

```text
Starting kernel ...

[    0.000000] Booting Linux on physical CPU 0x0
[    0.000000] Linux version 6.18.38-g50564c850d48 (runner@runnervmgx7h7) (arm-none-linux-gnueabihf-gcc (GNU Toolchain for the A-profile Architecture 10.3-2021.07 (arm-10.29)) 10.3.1 20210621, GNU ld (GNU Toolchain for the A-profile Architecture 10.3-2021.07 (arm-10.29)) 2.36.1.20210621) #1 SMP Mon Aug 31 11:04:42 UTC 2026
[    0.000000] CPU: ARMv7 Processor [414fc091] revision 1 (ARMv7), cr=18c5387d
[    0.000000] CPU: PIPT / VIPT nonaliasing data cache, VIPT aliasing instruction cache
[    0.000000] OF: fdt: Machine model: ZTE ZXHN E2631 (ZX279128S)
[    0.000000] earlycon: zteuart0 at MMIO 0x94404000 (options '')
[    0.000000] printk: legacy bootconsole [zteuart0] enabled
[    0.000000] Kernel command line: earlycon=zteuart,0x94404000 console=ttyAMA0,115200n8 rdinit=/init loglevel=8
[    0.000000] GIC: PPI11 is secure or misconfigured
[    0.044616] CPU: Testing write buffer coherency: ok
[    0.100985] smp: Bringing up secondary CPUs ...
[    0.105295] smp: Brought up 1 node, 1 CPU
[    0.115608] CPU: All CPU(s) started in SVC mode.
[    0.120373] Memory: 166436K/262144K available (13312K kernel code, 1571K rwdata, 5096K rodata, 5120K init, 263K bss, 28912K reserved, 65536K cma-reserved, 0K highmem)
[    0.135529] devtmpfs: initialized
[    0.222193] 94404000.serial: ttyAMA0 at MMIO 0x94404000 (irq = 25, base_baud = 0) is a PL011 rev1
[    0.229664] printk: console [ttyAMA0] enabled
[    0.238281] printk: legacy bootconsole [zteuart0] disabled
[    2.386138] Freeing unused kernel image (initmem) memory: 5120K
[    2.392434] Run /init as init process
=== E2631 mainline bring-up init reached userspace ===
[init] kernel booted, zteuart console OK
[init] Features : half thumb fastmult edsp thumbee tls
[init] handing console to busybox shell
/ # iptables -t mangle -L PREROUTING
/ # ip rule add fwmark 1 lookup 100
/ #
```

那份日志里的 `Memory: .../262144K` 对应 256 MiB —— 现在 `memory@40000000` 也按原厂 DT 写成
`<0x40000000 0x10000000>`，两者一致（这条之前是 128 MiB 的保守值，跟日志对不上）。

</details>

## 怎么把这块板子变成能跑的路由器

不在这棵树里，走 OpenWrt 那条：<https://github.com/Zlion-Y/zte-e2631-openwrt>
（升级包格式、槽头字段、CRC 规则、A/B 槽回退、Wi-Fi 现状和实测数据都写在它的 `docs/` 里）。
本仓库早期"从引导加载器用网络载入内核"那套脚本和镜像已退役，只留在 tag `v0.1.1`，
main 上不再维护，也不再提供任何引导步骤。

## 致谢

- [cnjn](https://github.com/cnjn/linux-mainline-zte-zxslc-sr1010) —— ZTE UART 的寄存器偏移、
  periphid、earlycon 逆向。本板的串口是同一代 IP，直接受益。
- [1234205a/zte-sr1010-research](https://github.com/1234205a/zte-sr1010-research) —— 原厂固件分析方法论。
- [ghahramani 的 OpenWrt PR #25469](https://github.com/openwrt/openwrt/pull/25469) —— ZX279128S 在 OpenWrt 里的第一版。

本移植不修改闪存、不含任何原厂密钥。

## 许可证

内核树：GPL-2.0。本移植新增的文件（DTS、defconfig、串口驱动改动）：GPL-2.0，
DTS 同时按 `BSD-2-Clause` 双许可，与上游设备树惯例一致。
