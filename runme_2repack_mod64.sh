#!/bin/sh

if [ -d work/kernel.sin-ramdisk ]; then

# Get device name
deviceprop=`cat work/kernel.sin-ramdisk/default.prop`
devicename=`echo ${deviceprop} | sed "s@.*ro\.bootimage\.build\.fingerprint=Sony\/\([a-zA-Z0-9_]*\).*@\1@"`
devicename_s=`echo ${devicename} | sed "s@\([a-zA-Z0-9]*\).*@\1@"`

# Check N
is_n=file_contexts.bin

# Go to ramdisk dir
cd work/kernel.sin-ramdisk

# Add support for /mnt/sdcard1 (thanks @monx®)
sed -i -e "s@symlink /storage/sdcard1 /sdcard1@symlink /storage/sdcard1 /sdcard1\n    symlink /storage/sdcard1 /mnt/sdcard1@g" init.qcom.rc

# Disable sony_ric
sed -i -e "s@mount securityfs securityfs /sys/kernel/security nosuid nodev noexec@mount securityfs securityfs /sys/kernel/security nosuid nodev noexec\n    write /sys/kernel/security/sony_ric/enable 0@g" init.sony-platform.rc
sed -i -e "s/service ric \/sbin\/ric/service ric \/sbin\/ric\n    disabled/g" init.sony-platform.rc

# Fix for Lollipop kernel
sed -i -e "s/chown tad tad \/dev\/block\/mmcblk0p1/chown root root \/dev\/block\/mmcblk0p1/g" init.sony-platform.rc
sed -i -e "s/chmod 0770 \/dev\/block\/mmcblk0p1/chmod 0777 \/dev\/block\/mmcblk0p1/g" init.sony-platform.rc
sed -i -e "s/user tad/user root/g" init.sony-platform.rc
sed -i -e "s/group tad root/group root root/g" init.sony-platform.rc

# Re-enable ethernet adapter support
sed -i -e "s@service scd /system/bin/scd@service dhcpcd_eth0 /system/bin/dhcpcd -B -d -t 30\n    class late_start\n    disabled\n    oneshot\n\nservice scd /system/bin/scd@g" init.sony-platform.rc

# Disable dm-verity
sed -i -e "s@wait,verify=.*fsmetadata@wait@g" fstab.qcom
sed -i -e "s@wait,verify@wait@g" fstab.qcom

# Disable force encryption
sed -i -e "s@forceencrypt@encryptable@g" fstab.qcom

# Re-enable tap to wake support
if expr $devicename : "maple.*" > /dev/null; then
sed -i -e "s@# Touch@# Touch\non property:persist.sys.touch.easywakeup=0\n    write /sys/devices/virtual/input/clearpad/wakeup_gesture 0\n\non property:persist.sys.touch.easywakeup=1\n    write /sys/devices/virtual/input/clearpad/wakeup_gesture 1\n@g" init.sony-device-common.rc
fi

# Compress ramdisk
find ./* | sudo cpio -o -H newc | sudo gzip -9 > ../../ramdisk_$devicename.cpio.gz

fi
