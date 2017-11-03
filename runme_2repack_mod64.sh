#!/bin/sh

if [ -d work/kernel.sin-ramdisk ]; then

# Get device name
deviceprop=`cat work/kernel.sin-ramdisk/default.prop`
devicename=`echo ${deviceprop} | sed "s@.*ro\.bootimage\.build\.fingerprint=Sony\/\([a-zA-Z0-9_]*\).*@\1@"`
devicename_s=`echo ${devicename} | sed "s@\([a-zA-Z0-9]*\).*@\1@"`

# Check O
is_o=plat_file_contexts

# Copy script for init.d dir
cp tools/androplus.sh work/kernel.sin-ramdisk/sbin/androplus.sh
chmod 777 work/kernel.sin-ramdisk/sbin/androplus.sh

# Copy busybox
cp tools/busybox work/kernel.sin-ramdisk/sbin/busybox
chmod 777 work/kernel.sin-ramdisk/sbin/busybox

# Go to ramdisk dir
cd work/kernel.sin-ramdisk

# Run script
echo "\non property:sys.boot_completed=1\n    start androplus_script\n\nservice androplus_script /sbin/androplus.sh\n    oneshot\n    class late_start\n    user root\n    group root\n    disabled\n    seclabel u:r:init:s0" >> init.rc

# Fix for Lollipop kernel
sed -i -e "s/chown tad tad \/dev\/block\/mmcblk0p1/chown root root \/dev\/block\/mmcblk0p1/g" init.sony-platform.rc
sed -i -e "s/chmod 0770 \/dev\/block\/mmcblk0p1/chmod 0777 \/dev\/block\/mmcblk0p1/g" init.sony-platform.rc
sed -i -e "s/user tad/user root/g" init.sony-platform.rc
sed -i -e "s/group tad root/group root root/g" init.sony-platform.rc

# Re-enable ethernet adapter support
sed -i -e "s@service scd /system/bin/scd@service dhcpcd_eth0 /system/bin/dhcpcd -B -d -t 30\n    class late_start\n    disabled\n    oneshot\n\nservice scd /system/bin/scd@g" init.sony-platform.rc

# Workaround for MultiROM
sed -i -e "s@write /sys/class/android_usb/android0/f_rndis/wceis 1@write /sys/class/android_usb/android0/f_rndis/wceis 1\n    chmod 750 /init.usbmode.sh@g" init.sony.usb.rc

# Add loop device support
sed -i -e "s@export ASEC_MOUNTPOINT /mnt/asec@export ASEC_MOUNTPOINT /mnt/asec\n    export LOOP_MOUNTPOINT /mnt/obb@g" init.environ.rc

# Re-enable tap to wake support
if expr $devicename : "maple.*" > /dev/null; then
sed -i -e "s@# Touch@# Touch\non property:persist.sys.touch.easywakeup=0\n    write /sys/devices/virtual/input/clearpad/wakeup_gesture 0\n\non property:persist.sys.touch.easywakeup=1\n    write /sys/devices/virtual/input/clearpad/wakeup_gesture 1\n@g" init.sony-device-common.rc
fi

# Add sToRm// DRM fix support
#if expr $devicename : "maple.*" > /dev/null; then
#sed -i -e "s@export ASEC_MOUNTPOINT /mnt/asec@export ASEC_MOUNTPOINT /mnt/asec\n    export LD_PRELOAD drmfix.so:drmfuck.so@g" init.environ.rc
#fi

# Compress ramdisk
find ./* | sudo cpio -o -H newc | sudo gzip -9 > ../../ramdisk_$devicename.cpio.gz

fi
