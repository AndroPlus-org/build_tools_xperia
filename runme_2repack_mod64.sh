#!/bin/sh

if [ -d work/kernel.sin-ramdisk ]; then

# Get device name
deviceprop=`cat work/kernel.sin-ramdisk/default.prop`
devicename=`echo ${deviceprop} | sed "s@.*ro\.bootimage\.build\.fingerprint=Sony\/\([a-zA-Z0-9_]*\).*@\1@"`
devicename_s=`echo ${devicename} | sed "s@\([a-zA-Z0-9]*\).*@\1@"`

# Check N
is_n=file_contexts.bin

# Copy script for init.d dir
cp tools/androplus.sh work/kernel.sin-ramdisk/sbin/androplus.sh
chmod 777 work/kernel.sin-ramdisk/sbin/androplus.sh

# Copy busybox
cp tools/busybox work/kernel.sin-ramdisk/sbin/busybox
chmod 777 work/kernel.sin-ramdisk/sbin/busybox

# Copy files for DRM patch
if expr $devicename : "maple.*" > /dev/null; then
<< "#__CO__"
	rm -f work/kernel.sin-ramdisk/vendor
	cp -a tools/vendor work/kernel.sin-ramdisk/vendor
	cp -a tools/init.vendor_ovl.sh work/kernel.sin-ramdisk/init.vendor_ovl.sh
#__CO__
elif ! expr $devicename : "karin.*" > /dev/null; then
	#rm -f work/kernel.sin-ramdisk/vendor
	#cp -a tools/vendor work/kernel.sin-ramdisk/vendor
	#cp -a tools/init.vendor_ovl.sh work/kernel.sin-ramdisk/init.vendor_ovl.sh
	cp tools/lib-preload64.so work/kernel.sin-ramdisk/lib/lib-preload64.so
fi


# Hijack init
if expr $devicename : "maple.*" > /dev/null; then
	cp -a tools/sony_init/$devicename_s/init_sony work/kernel.sin-ramdisk/sbin/init_sony
	cp -a tools/sony_init/keycheck work/kernel.sin-ramdisk/sbin/keycheck
	cp -a tools/sony_init/toybox_init work/kernel.sin-ramdisk/sbin/toybox_init
fi

<< "#__CO__"
# Copy bootrec files
if expr $devicename : "sumire.*" > /dev/null || expr $devicename : "suzuran.*" > /dev/null || expr $devicename : "karin.*" > /dev/null; then
	cp -a tools/twrp-sony-recovery-boot-script/bootrec work/kernel.sin-ramdisk/bootrec
else
	cp -a tools/twrp-sony-recovery-boot-script-XP/bootrec work/kernel.sin-ramdisk/bootrec
	sed -i -e "s@PLEASECHANGETHIS@$devicename_s@g" work/kernel.sin-ramdisk/bootrec/init.sh
fi
#__CO__
<< "#__CO__"
if [ ! -e work/kernel.sin-ramdisk/${is_n} ]; then
	if expr $devicename : "sumire.*" > /dev/null || expr $devicename : "suzuran.*" > /dev/null || expr $devicename : "karin.*" > /dev/null; then
		cp -a tools/twrp-sony-recovery-boot-script/bootrec work/kernel.sin-ramdisk/bootrec
	else
		cp -a tools/twrp-sony-recovery-boot-script-XP/bootrec work/kernel.sin-ramdisk/bootrec
		sed -i -e "s@PLEASECHANGETHIS@$devicename_s@g" work/kernel.sin-ramdisk/bootrec/init.sh
	fi
else
	cp -a tools/vendor/bin/bootimg work/kernel.sin-ramdisk/sbin/bootimg
	cp -a tools/vendor/bin/busybox work/kernel.sin-ramdisk/sbin/busybox
	cp -a tools/vendor/bin/extract_elf_ramdisk work/kernel.sin-ramdisk/sbin/extract_elf_ramdisk
	cp -a tools/init.hijack work/kernel.sin-ramdisk/init.hijack
fi
#__CO__

# Go to ramdisk dir
cd work/kernel.sin-ramdisk

# Disable wiping data in case you don't want to loose your data accidentally
#mv sbin/mr sbin/mr_old
#mv sbin/wipedata sbin/wipedata_old
#sed -i -e "s@exec u:r:vold:s0 -- /sbin/mr@#exec u:r:vold:s0 -- /sbin/mr@g" init.sony-platform.rc
#sed -i -e "s@exec u:r:vold:s0 -- /sbin/wipedata check-full-wipe@#exec u:r:vold:s0 -- /sbin/wipedata check-full-wipe@g" init.sony-platform.rc
#sed -i -e "s@exec u:r:installd:s0 -- /sbin/wipedata check-keep-media-wipe@#exec u:r:installd:s0 -- /sbin/wipedata check-keep-media-wipe@g" init.sony-platform.rc
#sed -i -e "s@exec u:r:vold:s0 -- /sbin/wipedata check-umount@#exec u:r:vold:s0 -- /sbin/wipedata check-umount@g" init.sony-platform.rc

# Hijack init
if expr $devicename : "maple.*" > /dev/null; then
	mv init init.real
	ln -s /sbin/init_sony init
elif [ ! -e ${is_n} ]; then
	mv init init.real
	ln -s /bootrec/init.sh init
fi

# Enable insecure adb
#sed -i -e "s/persist\.sys\.usb\.config=mtp/persist\.sys\.usb\.config=mtp,adb/g" default.prop
#sed -i -e "s/ro\.secure=1/ro\.secure=0/g" default.prop
#sed -i -e "s/ro\.debuggable=0/ro\.debuggable=1/g" default.prop

# Run script
echo "\non property:sys.boot_completed=1\n    start androplus_script\n\nservice androplus_script /sbin/androplus.sh\n    oneshot\n    class late_start\n    user root\n    group root\n    disabled\n    seclabel u:r:init:s0" >> init.rc

# Add support for /mnt/sdcard1 (thanks @monx®)
sed -i -e "s@symlink /storage/sdcard1 /sdcard1@symlink /storage/sdcard1 /sdcard1\n    symlink /storage/sdcard1 /mnt/sdcard1@g" init.qcom.rc

# Disable sony_ric
sed -i -e "s@mount securityfs securityfs /sys/kernel/security nosuid nodev noexec@mount securityfs securityfs /sys/kernel/security nosuid nodev noexec\n    write /sys/kernel/security/sony_ric/enable 0@g" init.sony-platform.rc
sed -i -e "s/service ric \/sbin\/ric/service ric \/sbin\/ric\n    disabled/g" init.sony-platform.rc

# Restore DRM functions
if expr $devicename : "maple.*" > /dev/null; then
<< "#__CO__"
	sed -i -e "s@on early-init@on early-init\n    restorecon /vendor/lib64/libdrmfix.so\n    restorecon /vendor/lib/libdrmfix.so\n@g" init.rc
	sed -i -e "s@trigger fs@trigger fs\n    trigger vendor-ovl@g" init.rc
	echo "on vendor-ovl" >> init.rc
	echo "    mount securityfs securityfs /sys/kernel/security nosuid nodev noexec" >> init.rc
	echo "    chmod 0640 /sys/kernel/security/sony_ric/enable" >> init.rc
	echo "    write /sys/kernel/security/sony_ric/enable 0" >> init.rc
	echo "    mount none /system/vendor/lib /vendor/lib/bind_lib bind" >> init.rc
	echo "    mount none /system/vendor/lib64 /vendor/lib64/bind_lib64 bind" >> init.rc
	echo "    exec u:r:init:s0 -- /system/bin/sh /init.vendor_ovl.sh /vendor" >> init.rc
	echo "    restorecon_recursive /vendor" >> init.rc
	#sed -i -e 's@start qseecomd@export LD_PRELOAD libdrmfix.so\n    start qseecomd@g' init.target.rc
#__CO__
elif ! expr $devicename : "karin.*" > /dev/null; then
if [ -e ${is_n} ]; then
<< "#__CO__"
	echo "" >> init.environ.rc
	echo "export LD_PRELOAD libdrmfix.so" >> init.environ.rc
	sed -i -e "s@on early-init@on early-init\n    restorecon /vendor/lib64/libdrmfix.so\n    restorecon /vendor/lib/libdrmfix.so@g" init.rc
	sed -i -e "s@trigger fs@trigger fs\n    trigger vendor-ovl@g" init.rc
	echo "on vendor-ovl" >> init.rc
	echo "    mount securityfs securityfs /sys/kernel/security nosuid nodev noexec" >> init.rc
	echo "    chmod 0640 /sys/kernel/security/sony_ric/enable" >> init.rc
	echo "    write /sys/kernel/security/sony_ric/enable 0" >> init.rc
	echo "    mount none /system/vendor/lib /vendor/lib/bind_lib bind" >> init.rc
	echo "    mount none /system/vendor/lib64 /vendor/lib64/bind_lib64 bind" >> init.rc
	echo "    exec u:r:init:s0 -- /system/bin/sh /init.vendor_ovl.sh /vendor" >> init.rc
	echo "    restorecon_recursive /vendor" >> init.rc
#__CO__
	sed -i -e "s@service keyprovd /system/bin/keyprovd@service keyprovd /system/bin/keyprovd\n    setenv LD_PRELOAD /lib/lib-preload64.so@g" init.sony-device-common.rc
	sed -i -e "s@service credmgrd /system/bin/credmgrd@service credmgrd /system/bin/credmgrd\n    setenv LD_PRELOAD /lib/lib-preload64.so@g" init.sony.rc
	sed -i -e "s@service secd /system/bin/secd@service secd /system/bin/secd\n    setenv LD_PRELOAD /lib/lib-preload64.so@g" init.sony.rc
	sed -i -e 's@export LD_PRELOAD libNimsWrap.so@export LD_PRELOAD libNimsWrap.so:/lib/lib-preload64.so@g' init.target.rc
else
	echo "" >> init.rc
	echo "on vendor-ovl" >> init.rc
	echo "    mount /system" >> init.rc
	echo "    exec u:r:init:s0 -- /system/bin/sh /init.vendor_ovl.sh /vendor" >> init.rc
	echo "    restorecon_recursive /vendor" >> init.rc
	sed -i -e "s!\(.*\)\(trigger post-fs\)\$!\1trigger vendor-ovl\n\1\2!" init.rc
	sed -i -e "s@service keyprovd /system/bin/keyprovd@service keyprovd /system/bin/keyprovd\n    setenv LD_PRELOAD /lib/lib-cred-inject.so:libdrmfix.so@g" init.sony-device-common.rc
	sed -i -e 's@export LD_PRELOAD libNimsWrap.so@export LD_PRELOAD libNimsWrap.so:libdrmfix.so@g' init.target.rc
	echo "/vendor(.*)		u:object_r:system_file:s0" >> file_contexts
fi
fi

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

# Add support for F2FS
sed -i -e "s@/dev/block/bootdevice/by-name/userdata@/dev/block/bootdevice/by-name/userdata  /data             f2fs    nosuid,nodev,noatime,inline_xattr,data_flush wait,check,encryptable=footer,resize\n/dev/block/bootdevice/by-name/userdata@g" fstab.qcom
sed -i -e "s@/dev/block/bootdevice/by-name/cache@/dev/block/bootdevice/by-name/cache     /cache            f2fs    nosuid,nodev,noatime,inline_xattr,flush_merge,data_flush                      wait,check\n/dev/block/bootdevice/by-name/cache@g" fstab.qcom

# Increase ZRAM
#sed -i -e "s@zramsize=536870912@zramsize=1073741824@g" fstab.qcom

# Workaround for MultiROM
sed -i -e "s@write /sys/class/android_usb/android0/f_rndis/wceis 1@write /sys/class/android_usb/android0/f_rndis/wceis 1\n    chmod 750 /init.usbmode.sh@g" init.sony.usb.rc

# Add loop device support
sed -i -e "s@export ASEC_MOUNTPOINT /mnt/asec@export ASEC_MOUNTPOINT /mnt/asec\n    export LOOP_MOUNTPOINT /mnt/obb@g" init.environ.rc

# Re-enable tap to wake support
if expr $devicename : "maple.*" > /dev/null; then
sed -i -e "s@# Touch@# Touch\non property:persist.sys.touch.easywakeup=0\n    write /sys/devices/virtual/input/clearpad/wakeup_gesture 0\n\non property:persist.sys.touch.easywakeup=1\n    write /sys/devices/virtual/input/clearpad/wakeup_gesture 1\n@g" init.sony-device-common.rc
fi

# Compress ramdisk
find ./* | sudo cpio -o -H newc | sudo gzip -9 > ../../ramdisk_$devicename.cpio.gz

fi
