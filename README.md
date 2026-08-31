# ZTE ZXHN E2631（ZX279128S）主线 Linux 移植

[English](README_EN.md)

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

## 完整启动日志（实测，点击展开）

<details>
<summary>U-Boot → 内核 6.18.38 → busybox shell 完整启动日志（2026-08-31 上板实测）</summary>

```text
Boot SPI NAND
start read bootheader
start read secondboot
non secure boot
Jump

enter bootloader...
crpm init enter
crpm init done
ddr init enter, rate is 1333 Mbps
ddr init done
serial init start
serial init done
SPI NAND
non secure uboot
backup header!!
Jump


U-Boot 2013.04 (Sep 25 2024 - 14:35:47)

CPU  : ZX279128S@A9,1000MHZ
Board: ZTE zx279128sevb
I2C:   ready
DRAM:  256 MiB
5,10000000,50000000
product_vid = 63
vid=63-E1630
input gpio:5
input gpio:15
input gpio:62
input gpio:61
input gpio:43
input gpio:47
input gpio:46
input gpio:45
output gpio:8,value:1
output gpio:40,value:1
output gpio:60,value:0
input gpio:18
input gpio:20
output gpio:55,value:0
output gpio:52,value:0
output gpio:54,value:0
output gpio:51,value:0
output gpio:2,value:0
bootsel=3
NAND:  manuid=1,15

Manu ID: 0x01, Chip ID: 0x15 (AMD SPI NAND HYF1GQ4UTACAE 128MiB 3,3V)
128 MiB
<nand_read_skip_bad_,411>!mtdpart=0x1,offset=0x0,mtdpartoffset=0xc0000,mtdPartsize=0x40000,length=0x20000
In:    serial
Out:   serial
Err:   serial
clk_pll env is not setted, core clk won't change
Net:   enter ref_clk_set.. mode = 0 .
enter pll_cfg_fractional
ref_clk_set success!
gpon serdes init
rxpll_ready
addr 0x9400004c before value is 38000
addr 0x9400004c after value is 381ff
eth0
pdt_cspboot_init:1035 Start to initialize cspboot...
zteboot_info_default_init:1298 zboot info inited
pdt_cspboot_info_init:1014 memtop:42000000 entry:40008000
pdt_cspboot_init:1069 Cspboot initialization is done.
*** Press 1 means entering boot mode***                                                              0
cspboot:1510 Entering boot mode ...
*** Please input bootmode password: ***
***********

Hit 1 to upgrade software version
Hit any key to stop autoboot:  0
=> setenv ipaddr 192.168.10.66
Unknown command 'setenv' - try 'help'
=> setenv ipaddr 192.168.10.66
Unknown command 'setenv' - try 'help'
=> setenv ipaddr 192.168.10.66
=> setenv serverip 192.168.10.1
=> tftp 0x43000000 uImage-e2631.img
mac 2 phy status changed: 1000M full-duplex
-----smac_init
Using eth0 device
TFTP from server 192.168.10.1; our IP address is 192.168.10.66
Filename 'uImage-e2631.img'.
Load address: 0x43000000
Loading: #################################################################
         #################################################################
         ...(13.3MB 传输进度省略)...
         #################################################################
         ####
         2.8 MiB/s
done
Bytes transferred = 13328020 (cb5e94 hex)
=> bootm 0x43000000
## Booting kernel from Legacy Image at 43000000 ...
   Image Name:   E2631-mainline-6.18
   Image Type:   ARM Linux Kernel Image (uncompressed)
   Data Size:    13327956 Bytes = 12.7 MiB
   Load Address: 40008000
   Entry Point:  40008000
   Verifying Checksum ... OK
   Loading Kernel Image ... OK
OK
getenv error!----------------------
|-->setup versioninfo tag...

Starting kernel ...

[    0.000000] Booting Linux on physical CPU 0x0
[    0.000000] Linux version 6.18.38-g50564c850d48 (runner@runnervmgx7h7) (arm-none-linux-gnueabihf-gcc (GNU Toolchain for the A-profile Architecture 10.3-2021.07 (arm-10.29)) 10.3.1 20210621, GNU ld (GNU Toolchain for the A-profile Architecture 10.3-2021.07 (arm-10.29)) 2.36.1.20210621) #1 SMP Mon Aug 31 11:04:42 UTC 2026
[    0.000000] CPU: ARMv7 Processor [414fc091] revision 1 (ARMv7), cr=18c5387d
[    0.000000] CPU: PIPT / VIPT nonaliasing data cache, VIPT aliasing instruction cache
[    0.000000] OF: fdt: Machine model: ZTE ZXHN E2631 (ZX279128S)
[    0.000000] earlycon: zteuart0 at MMIO 0x94404000 (options '')
[    0.000000] printk: legacy bootconsole [zteuart0] enabled
[    0.000000] Memory policy: Data cache writealloc
[    0.000000] efi: UEFI not found.
[    0.000000] cma: Reserved 64 MiB at 0x4c000000
[    0.000000] Zone ranges:
[    0.000000]   Normal   [mem 0x0000000040000000-0x000000004fffffff]
[    0.000000]   HighMem  empty
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x0000000040000000-0x000000004fffffff]
[    0.000000] Initmem setup node 0 [mem 0x0000000040000000-0x000000004fffffff]
[    0.000000] OF: reserved mem: Reserved memory: No reserved-memory node in the DT
[    0.000000] percpu: Embedded 17 pages/cpu s39564 r8192 d21876 u69632
[    0.000000] pcpu-alloc: s39564 r8192 d21876 u69632 alloc=17*4096
[    0.000000] pcpu-alloc: [0] 0
[    0.000000] Kernel command line: earlycon=zteuart,0x94404000 console=ttyAMA0,115200n8 rdinit=/init loglevel=8
[    0.000000] printk: log buffer data + meta data: 131072 + 409600 = 540672 bytes
[    0.000000] Dentry cache hash table entries: 32768 (order: 5, 131072 bytes, linear)
[    0.000000] Inode-cache hash table entries: 16384 (order: 4, 65536 bytes, linear)
[    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 65536
[    0.000000] mem auto-init: stack:off, heap alloc:off, heap free:off
[    0.000000] SLUB: HWalign=32, Order=0-3, MinObjects=0, CPUs=1, Nodes=1
[    0.000000] rcu: Hierarchical RCU implementation.
[    0.000000] rcu:     RCU event tracing is enabled.
[    0.000000] rcu:     RCU restricting CPUs from NR_CPUS=16 to nr_cpu_ids=1.
[    0.000000]  Tracing variant of Tasks RCU enabled.
[    0.000000] rcu: RCU calculated value of scheduler-enlistment delay is 10 jiffies.
[    0.000000] rcu: Adjusting geometry for rcu_fanout_leaf=16, nr_cpu_ids=1
[    0.000000] RCU Tasks Trace: Setting shift to 0 and lim to 1 rcu_task_cb_adjust=1 rcu_task_cpu_ids=1.
[    0.000000] NR_IRQS: 16, nr_irqs: 16, preallocated irqs: 16
[    0.000000] L2C-310 erratum 769419 enabled
[    0.000000] L2C-310 enabling early BRESP for Cortex-A9
[    0.000000] L2C-310 full line of zeros enabled for Cortex-A9
[    0.000000] L2C-310 dynamic clock gating enabled, standby mode enabled
[    0.000000] L2C-310 cache controller enabled, 16 ways, 256 kB
[    0.000000] L2C-310: CACHE_ID 0x410000c9, AUX_CTRL 0x46030001
[    0.000000] rcu: srcu_init: Setting srcu_struct sizes based on contention.
[    0.000000] GIC: PPI11 is secure or misconfigured
[    0.000000] sched_clock: 64 bits at 500MHz, resolution 2ns, wraps every 4398046511103ns
[    0.007980] clocksource: arm_global_timer: mask: 0xffffffffffffffff max_cycles: 0xe6a171a037, max_idle_ns: 881590485102 ns
[    0.019011] GIC: PPI11 is secure or misconfigured
[    0.023690] Switching to timer-based delay loop, resolution 2ns
[    0.029825] Console: colour dummy device 80x30
[    0.034051] Calibrating delay loop (skipped), value calculated using timer frequency.. 1000.00 BogoMIPS (lpj=5000000)
[    0.044616] CPU: Testing write buffer coherency: ok
[    0.049473] CPU0: Spectre v2: using BPIALL workaround
[    0.054500] pid_max: default: 32768 minimum: 301
[    0.059234] Mount-cache hash table entries: 1024 (order: 0, 4096 bytes, linear)
[    0.066393] Mountpoint-cache hash table entries: 1024 (order: 0, 4096 bytes, linear)
[    0.074899] CPU0: thread -1, cpu 0, socket 0, mpidr 80000000
[    0.080954] Setting up static identity map for 0x40100000 - 0x40100060
[    0.086529] rcu: Hierarchical SRCU implementation.
[    0.091078] rcu:     Max phase no-delay instances is 1000.
[    0.097278] EFI services will not be available.
[    0.100985] smp: Bringing up secondary CPUs ...
[    0.105295] smp: Brought up 1 node, 1 CPU
[    0.109306] SMP: Total of 1 processors activated (1000.00 BogoMIPS).
[    0.115608] CPU: All CPU(s) started in SVC mode.
[    0.120373] Memory: 166436K/262144K available (13312K kernel code, 1571K rwdata, 5096K rodata, 5120K init, 263K bss, 28912K reserved, 65536K cma-reserved, 0K highmem)
[    0.135529] devtmpfs: initialized
[    0.139806] VFP support v0.3: not present
[    0.142680] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604462750000 ns
[    0.152217] posixtimers hash table entries: 512 (order: 0, 4096 bytes, linear)
[    0.159393] futex hash table entries: 256 (16384 bytes on 1 NUMA nodes, total 16 KiB, linear).
[    0.169590] pinctrl core: initialized pinctrl subsystem
[    0.174020] DMI not present or invalid.
[    0.177771] NET: Registered PF_NETLINK/PF_ROUTE protocol family
[    0.185246] DMA: preallocated 256 KiB pool for atomic coherent allocations
[    0.191606] thermal_sys: Registered thermal governor 'step_wise'
[    0.191696] cpuidle: using governor menu
[    0.200681] No ATAGs?
[    0.202847] hw-breakpoint: found 5 (+1 reserved) breakpoint and 1 watchpoint registers.
[    0.210807] hw-breakpoint: maximum watchpoint size is 4 bytes.
[    0.216870] Serial: AMBA PL011 UART driver
[    0.222193] 94404000.serial: ttyAMA0 at MMIO 0x94404000 (irq = 25, base_baud = 0) is a PL011 rev1
[    0.229664] printk: console [ttyAMA0] enabled
[    0.229664] printk: console [ttyAMA0] enabled
[    0.238281] printk: legacy bootconsole [zteuart0] disabled
[    0.238281] printk: legacy bootconsole [zteuart0] disabled
[    0.250329] uart-pl011 94405000.serial: aliased and non-aliased serial devices found in device tree. Serial port enumeration may be unpredictable.
[    0.250678] 94405000.serial: ttyAMA1 at MMIO 0x94405000 (irq = 26, base_baud = 0) is a PL011 rev1
[    0.281101] iommu: Default domain type: Translated
[    0.281146] iommu: DMA domain TLB invalidation policy: strict mode
[    0.292778] SCSI subsystem initialized
[    0.296790] libata version 3.00 loaded.
[    0.297117] pps_core: LinuxPPS API ver. 1 registered
[    0.297132] pps_core: Software ver. 5.3.6 - Copyright 2005-2007 Rodolfo Giometti <giometti@linux.it>
[    0.297153] PTP clock support registered
[    0.297195] EDAC MC: Ver: 3.0.0
[    0.322638] scmi_core: SCMI protocol bus registered
[    0.339124] nfc: nfc_init: NFC Core ver 0.1
[    0.339237] NET: Registered PF_NFC protocol family
[    0.348421] vgaarb: loaded
[    0.351581] clocksource: Switched to clocksource arm_global_timer
[    0.372777] NET: Registered PF_INET protocol family
[    0.372975] IP idents hash table entries: 4096 (order: 3, 32768 bytes, linear)
[    0.373733] tcp_listen_portaddr_hash hash table entries: 512 (order: 0, 4096 bytes, linear)
[    0.373771] Table-perturb hash table entries: 65536 (order: 6, 262144 bytes, linear)
[    0.373792] TCP established hash table entries: 2048 (order: 1, 8192 bytes, linear)
[    0.373818] TCP bind hash table entries: 2048 (order: 3, 32768 bytes, linear)
[    0.373887] TCP: Hash tables configured (established 2048 bind 2048)
[    0.373967] UDP hash table entries: 256 (order: 2, 14336 bytes, linear)
[    0.374022] UDP-Lite hash table entries: 256 (order: 2, 14336 bytes, linear)
[    0.374214] NET: Registered PF_UNIX/PF_LOCAL protocol family
[    0.443787] RPC: Registered named UNIX socket transport module.
[    0.443817] RPC: Registered udp transport module.
[    0.443824] RPC: Registered tcp transport module.
[    0.443830] RPC: Registered tcp-with-tls transport module.
[    0.443835] RPC: Registered tcp NFSv4.1 backchannel transport module.
[    0.443849] PCI: CLS 0 bytes, default 64
[    0.492013] workingset: timestamp_bits=30 max_order=16 bucket_order=0
[    0.492440] squashfs: version 4.0 (2009/01/31) Phillip Lougher
[    0.512305] NFS: Registering the id_resolver key type
[    0.512372] Key type id_resolver registered
[    0.512381] Key type id_legacy registered
[    0.512411] nfs4filelayout_init: NFSv4 File Layout Driver Registering...
[    0.512421] nfs4flexfilelayout_init: NFSv4 Flexfile Layout Driver Registering...
[    0.512485] jffs2: version 2.2. (NAND) © 2001-2006 Red Hat, Inc.
[    0.546478] Block layer SCSI generic (bsg) driver version 0.4 loaded (major 245)
[    0.546512] io scheduler mq-deadline registered
[    0.546521] io scheduler kyber registered
[    0.546557] io scheduler bfq registered
[    0.567162] ledtrig-cpu: registered to indicate activity on CPUs
[    0.742032] Serial: 8250/16550 driver, 5 ports, IRQ sharing enabled
[    0.750917] STMicroelectronics ASC driver initialized
[    0.808106] brd: module loaded
[    0.824665] loop: module loaded
[    0.828443] zram: Added device: zram0
[    0.845442] tun: Universal TUN/TAP device driver, 1.6
[    0.852411] CAN device driver interface
[    0.852616] e1000e: Intel(R) PRO/1000 Network Driver
[    0.852626] e1000e: Copyright(c) 1999 - 2015 Intel Corporation.
[    0.852685] igb: Intel(R) Gigabit Ethernet Network Driver
[    0.852694] igb: Copyright (c) 2007-2014 Intel Corporation.
[    0.853743] i2c_dev: i2c /dev entries driver
[    0.854742] sdhci: Secure Digital Host Controller Interface driver
[    0.854757] sdhci: Copyright(c) Pierre Ossman
[    0.854800] Synopsys Designware Multimedia Card Interface Driver
[    0.854886] sdhci-pltfm: SDHCI platform and OF driver helper
[    0.856340] NET: Registered PF_INET6 protocol family
[    0.932040] Segment Routing with IPv6
[    0.932130] In-situ OAM (IOAM) with IPv6
[    0.932279] sit: IPv6, IPv4 and MPLS over IPv4 tunneling driver
[    0.932922] NET: Registered PF_PACKET protocol family
[    0.932944] can: controller area network core
[    0.932994] NET: Registered PF_CAN protocol family
[    0.933006] can: raw protocol
[    0.933016] can: broadcast manager protocol
[    0.933028] can: netlink gateway - max_hops=1
[    0.933250] Key type dns_resolver registered
[    0.933433] ThumbEE CPU extension supported.
[    0.933455] Registering SWP/SWPB emulation handler
[    2.372418] clk: Disabling unused clocks
[    2.372461] PM: genpd: Disabling unused power domains
[    2.386138] Freeing unused kernel image (initmem) memory: 5120K
[    2.392434] Run /init as init process
[    2.392454]   with arguments:
[    2.392462]     /init
[    2.392469]   with environment:
[    2.392474]     HOME=/
[    2.392480]     TERM=linux

=== E2631 mainline bring-up init reached userspace ===
[init] kernel booted, zteuart console OK
[init] Features : half thumb fastmult edsp thumbee tls
[init] soft-float probe: 1234.5*0.25+1 x4 = 6.1504 (expect 6.1504)
[init] handing console to busybox shell


BusyBox v1.17.2 (2024-09-25 14:57:47 CST) built-in shell (ash)
Enter 'help' for a list of built-in commands.

/ #
```

</details>

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

本仓库就是**完整的 Linux 内核源码树**（Linux 6.18.38 + E2631 平台适配全部落树），
clone 后直接构建，不需要单独拉基础树或套补丁。

```
arch/arm/boot/dts/zte/zx279128s-e2631.dts   板级设备树（含 zte 子目录 Makefile）
arch/arm/configs/zx279128s_e2631_defconfig  精简 defconfig（initramfs 已内嵌）
initramfs-e2631.cpio.gz                     内嵌 initramfs（busybox + uClibc + init）
e2631-tools/                                配套工具
│  tftpd2.py           简易 TFTP 服务器（UDP 69）
│  pack_uimage.py      uImage 打包（load/entry 0x40008000）
│  serial_ctl.py       串口驱动（驱动 U-Boot 用）
│  bootflow2.py        脚本化 tftp + bootm 串口序列
│  mkconfig.sh / cleanbuild3.sh / mihomobuild.sh    MSYS2 构建步骤
│  initramfs-src/      init.c + pack2.py（initramfs 构建源）
upstream-series/       cnjn 的 ZX279133 16 补丁集（6.18.38 基线，参考）
research.md            内核版本调研笔记
README / README.md / README_EN.md
build.sh / build.bat   一键编译脚本（Linux/WSL 与 Windows/MSYS2）
.github/workflows/build.yml    CI：main + v* tag 构建并发布 Release
```

编译产物不进仓库，由 CI 发布到 GitHub Release（tag `v0.1.1` 已附带
`uImage-e2631.img`，可直接下载引导）。

## 编译

clone 后直接在树内构建，以下命令与 CI 完全一致（无需套补丁）。

Linux / WSL（先安装 Arm GNU Toolchain 10.3，把 `bin` 加进 PATH）：

```bash
make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf- zx279128s_e2631_defconfig

make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf- -j$(nproc) zImage

make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf- zte/zx279128s-e2631.dtb

cat arch/arm/boot/zImage arch/arm/boot/dts/zte/zx279128s-e2631.dtb > zImage-dtb-e2631

python3 e2631-tools/pack_uimage.py zImage-dtb-e2631 uImage-e2631.img
```

产物 `uImage-e2631.img` 按上文 TFTP 引导即可。

Windows（MSYS2 + Arm GNU Toolchain mingw 宿主）跑同一套命令，注意：

- `make -j4` 上限（更高 `-j` 在 MSYS2 下不稳定）；
- arch/arm/Makefile 里已强制 `-marm`（mingw 工具链默认 Thumb）；
- fixdep / gen_init_cpio 带了 CRLF 兼容补丁。

或者直接用 GitHub Actions：fork 后 push（或手动 `workflow_dispatch`），
产物在 Actions 页面 / Release 下载，零本机环境。

## 快速开始（接手者必读）

三种方式，任选其一：

| 方式 | 命令 | 适用 |
|---|---|---|
| **Linux / WSL2** | `./build.sh` | 推荐，树内一键编译打包 |
| **Windows 原生** | `build.bat` | 自动装 MSYS2 + 工具链后编译（较慢，首次自动下载） |
| **GitHub Actions** | fork 后 push | 零环境，云端编译，Actions 页面 / Release 下载 uImage |

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
