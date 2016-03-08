#!/bin/sh

# Get device name
crashtag=`cat work/kernel.sin-ramdisk/crashtag`
devicename=`echo ${crashtag} | sed "s/.*-\([a-zA-Z0-9]*\).*/\1/"`

# Copy genfstab.rhine
#cp tools/genfstab.rhine work/kernel.sin-ramdisk/sbin/genfstab.rhine
#chmod 777 work/kernel.sin-ramdisk/sbin/genfstab.rhine

# Copy script for init.d dir
cp tools/androplus.sh work/kernel.sin-ramdisk/sbin/androplus.sh
chmod 777 work/kernel.sin-ramdisk/sbin/androplus.sh

# Copy busybox
cp tools/busybox work/kernel.sin-ramdisk/sbin/busybox
chmod 777 work/kernel.sin-ramdisk/sbin/busybox

# Copy lib-cred-inject.so
if [ $devicename != 'SGP7' ]; then
mkdir -p work/kernel.sin-ramdisk/lib
cp tools/lib-cred-inject.so work/kernel.sin-ramdisk/lib/lib-cred-inject.so
chmod 644 work/kernel.sin-ramdisk/lib/lib-cred-inject.so
fi

# Copy rootsh and SuperSU
#cp -a tools/SuperSU_files work/kernel.sin-ramdisk/SuperSU_files
#cp tools/rootsh work/kernel.sin-ramdisk/sbin/rootsh
#sudo chmod a+x work/kernel.sin-ramdisk/sbin
#sudo chown root work/kernel.sin-ramdisk/sbin/rootsh
#sudo chgrp 2000 work/kernel.sin-ramdisk/sbin/rootsh
#sudo chmod 6750 work/kernel.sin-ramdisk/sbin/rootsh

# Copy bootrec files
cp -a tools/twrp-sony-recovery-boot-script/bootrec work/kernel.sin-ramdisk/bootrec

# Go to ramdisk dir
cd work/kernel.sin-ramdisk

# Hijack init
mv init init.real
ln -s /bootrec/init.sh init

# Changes for generating proper fstab
#rm -f fstab.qcom
#sed -i -e "s/start fsckwait/start fsckwait\n\n    # Generate proper fstab\n    exec \/sbin\/genfstab\.rhine/g" init.target.rc

# Make it insecure
#sed -i -e "s@write /sys/fs/selinux/checkreqprot 0@#write /sys/fs/selinux/checkreqprot 0@g" init.rc
#sed -i -e "s@mount rootfs rootfs / ro remount@mount rootfs rootfs / rw,suid remount\n    chmod 0755 /sbin\n    chown root system /sbin/rootsh\n    chmod 6755 /sbin/rootsh\n    chgrp 2000 sbin/rootsh\n@g" init.rc
#sed -i -e "s@chmod 0444 /sys/fs/selinux/policy@#chmod 0444 /sys/fs/selinux/policy@g" init.rc
#sed -i -e "s/setprop selinux\.reload_policy 1/#setprop selinux\.reload_policy 1/g" init.rc
#sed -i -e "s@/system/xbin/su		u:object_r:su_exec:s0@#/system/xbin/su		u:object_r:su_exec:s0@g" file_contexts
#sed -i -e "s@/system/bin/patchoat    u:object_r:dex2oat_exec:s0@/system/bin/patchoat    u:object_r:dex2oat_exec:s0\n\n#############################\n# SuperSU, init.d files and busybox\n#\n\n/sbin/su		u:object_r:system_file:s0\n\n/system/etc/install-recovery.sh	u:object_r:toolbox_exec:s0 \n/system/xbin/su		u:object_r:system_file:s0\n/system/bin/.ext/.su	u:object_r:system_file:s0\n/system/xbin/daemonsu	u:object_r:system_file:s0\n/system/xbin/sugote	u:object_r:zygote_exec:s0\n/system/xbin/supolicy	u:object_r:system_file:s0\n/system/lib64/libsupol.so	u:object_r:system_file:s0\n/system/xbin/sugote-mksh	u:object_r:system_file:s0\n/system/bin/app_process64_original	u:object_r:zygote_exec:s0\n/system/bin/app_process_init	u:object_r:system_file:s0\n/system/etc/.installed_su_daemon	u:object_r:system_file:s0\n/system/su.d(/*.)	u:object_r:system_file:s0\n\n/system/xbin/busybox	u:object_r:system_file:s0\n@g" file_contexts

# Enable insecure adb
#sed -i -e "s/persist\.sys\.usb\.config=mtp/persist\.sys\.usb\.config=mtp,adb/g" default.prop
sed -i -e "s/ro\.secure=1/ro\.secure=0/g" default.prop
sed -i -e "s/ro\.debuggable=0/ro\.debuggable=1/g" default.prop

# Run script
echo "\nservice androplus_script /sbin/androplus.sh\n    class main\n    user root\n    group root\n    oneshot" >> init.rc

# Tweak
#sed -i -e "s/sdcard -u 1023 -g 1023 -w 1023 -d/sdcard -u 1023 -g 1023 -w 1023 -t 4 -d/g" init.qcom.rc
#sed -i -e "s/on boot/on boot\n    # read ahead buffer\n    write \/sys\/block\/mmcblk0\/queue\/read_ahead_kb 2048\n    write \/sys\/block\/mmcblk1\/queue\/read_ahead_kb 2048/g" init.qcom.rc

# Add support for /mnt/sdcard1 (thanks @monx®)
sed -i -e "s@symlink /storage/sdcard1 /sdcard1@symlink /storage/sdcard1 /sdcard1\n    symlink /storage/sdcard1 /mnt/sdcard1@g" init.qcom.rc

# Disable sony_ric
sed -i -e "s@mount securityfs securityfs /sys/kernel/security nosuid nodev noexec@mount securityfs securityfs /sys/kernel/security nosuid nodev noexec\n    write /sys/kernel/security/sony_ric/enable 0@g" init.sony-platform.rc
sed -i -e "s/service ric \/sbin\/ric/service ric \/sbin\/ric\n    disabled/g" init.sony-platform.rc

# Restore DRM functions
if [ $devicename != 'SGP7' ]; then
sed -i -e 's@on post-fs-data@on post-fs-data\n    exec /system/xbin/supolicy --live "allow secd rootfs file execute"@g' init.sony.rc
sed -i -e "s@service secd /system/bin/secd@service secd /system/bin/secd\n    setenv LD_PRELOAD /lib/lib-cred-inject.so@g" init.sony.rc
sed -i -e "s@service keyprovd /system/bin/keyprovd@service keyprovd /system/bin/keyprovd\n    setenv LD_PRELOAD /lib/lib-cred-inject.so@g" init.sony-device-common.rc
fi

# Fix qmux
#sed -i -e "s/\/dev\/smdcntl7             0640   radio      radio/\/dev\/smdcntl7             0640   radio      radio\n\/dev\/smdcntl8             0640   radio      radio\n\/dev\/smdcntl9             0640   radio      radio\n\/dev\/smdcntl10            0640   radio      radio\n\/dev\/smdcntl11            0640   radio      radio/g" ueventd.qcom.rc
#sed -i -e "s/user radio/user root/g" init.qcom.rc

# Fix for Lollipop kernel
sed -i -e "s/chown tad tad \/dev\/block\/mmcblk0p1/chown root root \/dev\/block\/mmcblk0p1/g" init.sony-platform.rc
sed -i -e "s/chmod 0770 \/dev\/block\/mmcblk0p1/chmod 0777 \/dev\/block\/mmcblk0p1/g" init.sony-platform.rc
sed -i -e "s/user tad/user root/g" init.sony-platform.rc
sed -i -e "s/group tad root/group root root/g" init.sony-platform.rc

# Permissive
#xdelta patch ../../tools/init_permissive.xdelta init init.m
#mv init.m init

# other way
#sed 's/\x02\xF0\x46\xFB\xC1\x49\x01/\x02\xF0\x46\xFB\xC1\x49\x00/g' init > init_temp; rm init; mv init_temp init
#wait
#sed 's/\x0A\xF0\xCA\xF9\x01/\x0A\xF0\xCA\xF9\x00/g' init > init_temp2; rm init; mv init_temp2 init

#chmod 750 init

# Compress ramdisk
find ./* | sudo cpio -o -H newc | sudo gzip -9 > ../../ramdisk$devicename.cpio.gz
