#!/bin/bash
export PATH="/usr/bin:/d/Work/e2631-kernel/tc/gcc-arm-10.3-2021.07-mingw-w64-i686-arm-none-linux-gnueabihf/bin:$PATH"
cd /d/Work/e2631-kernel/sr1010-kernel || exit 1
M="make ARCH=arm CROSS_COMPILE=arm-none-linux-gnueabihf-"
$M multi_v7_defconfig > /dev/null 2>&1 || { echo DEFCONFIG-FAIL; exit 1; }
# mihomo fragment
while IFS= read -r line; do
  case "$line" in
    CONFIG_*=y) opt=${line%%=y}; ./scripts/config -e ${opt#CONFIG_} ;;
  esac
 done < /d/Work/e2631-kernel/config-mihomo.fragment
# cmdline + initramfs
./scripts/config --set-str CMDLINE "earlycon=zteuart,0x94404000 console=ttyAMA0,115200n8 rdinit=/init loglevel=8"
./scripts/config -e CMDLINE_FORCE
./scripts/config --set-str INITRAMFS_SOURCE "/d/Work/e2631-kernel/initramfs/initramfs.cpio.gz"
# slim platforms (keep VIRT/VEXPRESS)
for i in 1 2 3; do
  for c in $(grep -E "^CONFIG_(ARCH|SOC|MACH)_[A-Z0-9_]+=y" .config | sed "s/=y//;s/CONFIG_//" | grep -vE "MULTI|VIRT|VEXPRESS|_HAS_|_SUPPORTS|_WANT|_USE|_MIGHT|_HAVE|SUSPEND|HIBERN|_SELECT|OPTIONAL|KEEPUNMAP|SPARSE|STACK|_DMA|PROC|ENABLE|MIGRATE|NR_GPIO|SETS|DEVTMPFS|DEBUG"); do
    ./scripts/config -d $c
  done
  $M olddefconfig > /dev/null 2>&1
  for c in $(grep -E "^CONFIG_(ARCH|SOC|MACH)_[A-Z0-9_]+=y" .config | sed "s/=y//;s/CONFIG_//" | grep -vE "MULTI|VIRT|VEXPRESS|_HAS_|_SUPPORTS|_WANT|_USE|_MIGHT|_HAVE|SUSPEND|HIBERN|_SELECT|OPTIONAL|KEEPUNMAP|SPARSE|STACK|_DMA|PROC|ENABLE|MIGRATE|NR_GPIO|SETS|DEVTMPFS|DEBUG"); do
    ./scripts/config -d $c
  done
  $M olddefconfig > /dev/null 2>&1
done
# no usb
./scripts/config -d USB_SUPPORT -d USB -d USB_DWC2 -d USB_DWC2_PLATFORM -d USB_DWC3 -d USB_DWC3_HOST -d USB_USBNET -d USB_NET_CDCETHER -d USB_NET_CDC_NCM -d USB_RTL8152 -d USB_NET_AX88179_178A -d USB_NET_RNDIS_HOST -d USB_STORAGE -d SCSI -d BLK_DEV_SD
$M olddefconfig > /dev/null 2>&1
echo === VERIFY ===
for k in TUN NETFILTER_XT_TARGET_TPROXY NETFILTER_XT_MATCH_SOCKET NFT_TPROXY NFT_SOCKET NFT_CT NF_CONNTRACK NF_NAT NF_TABLES IP_NF_IPTABLES IP_NF_TARGET_REDIRECT IP_NF_TARGET_MASQUERADE IP6_NF_IPTABLES IP_ADVANCED_ROUTER IP_MULTIPLE_TABLES IPV6 ZRAM OVERLAY_FS VFP NEON MT7916E; do
  v=$(grep -E "^CONFIG_${k}=" .config | head -1)
  echo "${v:-MISSING:$k}"
done
$M savedefconfig > /dev/null 2>&1 && cp defconfig arch/arm/configs/zx279128s_e2631_defconfig && echo DEFCONFIG-SAVED
