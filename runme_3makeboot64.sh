#!/bin/sh

# Get device name
crashtag=`cat work/kernel.sin-ramdisk/crashtag`
devicename=`echo ${crashtag} | sed "s/.*-\([a-zA-Z0-9]*\).*/\1/"`

./tools/mkbootimg --base 0x00000000 --kernel work/kernel.sin-kernel --ramdisk_offset 0x02000000 --tags_offset 0x01E00000 --pagesize 4096 --cmdline "androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x237 ehci-hcd.park=3 lpm_levels.sleep_disabled=1 boot_cpus=0-5 dwc3_msm.prop_chg_detect=Y coherent_pool=2M dwc3_msm.hvdcp_max_current=1500" --ramdisk ramdisk$devicename.cpio.gz -o boot.img
