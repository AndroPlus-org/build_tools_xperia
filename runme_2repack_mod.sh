#!/bin/sh

# Copy genfstab.rhine
#cp tools/genfstab.rhine work/kernel.sin-ramdisk/sbin/genfstab.rhine
#chmod 777 work/kernel.sin-ramdisk/sbin/genfstab.rhine

# Copy script for init.d dir
cp tools/start_mpdec.sh work/kernel.sin-ramdisk/sbin/start_mpdec.sh
chmod 777 work/kernel.sin-ramdisk/sbin/start_mpdec.sh

#cp tools/set_options.sh work/kernel.sin-ramdisk/sbin/set_options.sh
#chmod 777 work/kernel.sin-ramdisk/sbin/set_options.sh

# Go to ramdisk dir
cd work/kernel.sin-ramdisk

# Changes for generating proper fstab
#rm -f fstab.qcom
#sed -i -e "s/start fsckwait/start fsckwait\n\n    # Generate proper fstab\n    exec \/sbin\/genfstab\.rhine/g" init.target.rc

# Do not reload policy
# sed -i -e "s/setprop selinux\.reload_policy 1/setprop selinux\.reload_policy 0/g" init.rc

# Enable insecure adb
sed -i -e "s/persist\.sys\.usb\.config=mtp/persist\.sys\.usb\.config=mtp,adb/g" default.prop
sed -i -e "s/ro\.secure=1/ro\.secure=0/g" default.prop
sed -i -e "s/ro\.debuggable=0/ro\.debuggable=1\npersist.adb.notify=0/g" default.prop

# Force enable camera API 2... maybe
#sed -i -e "s/camera2\.portability\.force_api=1/camera2\.portability\.force_api=2/g" default.prop

# Disable MP decision
#echo -e "\nservice androplus_script /sbin/stop_mpdec.sh\n    class main\n    user root\n    group root\n    oneshot" >> init.sony.rc

# Create init.d dir
echo -e "\nservice androplus_script /sbin/start_mpdec.sh\n    class main\n    user root\n    group root\n    oneshot" >> init.sony.rc

# Support init.d
echo -e "\nservice initd_support /system/bin/logwrapper /sbin/busybox run-parts /system/etc/init.d\n    class main\n    oneshot" >> init.rc
#echo -e "\non property:sys.boot_completed=1\n# Enable and configure intelli thermal\nwrite /sys/module/msm_thermal_v2/parameters/enabled Y\nwrite /sys/module/msm_thermal_v2/core_control/enabled 1 \nwrite /sys/module/msm_thermal_v2/parameters/core_limit_temp_degC 65\nwrite /sys/module/msm_thermal_v2/parameters/limit_temp_degC 70\nwrite /sys/module/msm_thermal_v2/parameters/poll_ms 250\nwrite /sys/module/msm_thermal_v2/vdd_restriction/enabled 0\nwrite /sys/module/msm_thermal_v2/parameters/core_control_mask 12\nwrite /sys/module/msm_thermal_v2/parameters/freq_control_mask 15\n\n# Enable intelli_plug\nwrite /sys/kernel/intelli_plug/intelli_plug_active 1" >> init.sony.rc

# Tweak
#sed -i -e "s/sdcard -u 1023 -g 1023 -w 1023 -d/sdcard -u 1023 -g 1023 -w 1023 -t 4 -d/g" init.qcom.rc
#sed -i -e "s/on boot/on boot\n    # read ahead buffer\n    write \/sys\/block\/mmcblk0\/queue\/read_ahead_kb 2048\n    write \/sys\/block\/mmcblk1\/queue\/read_ahead_kb 2048/g" init.qcom.rc

# Quick Charge 2.0
sed -i -e 's/on boot/on boot\n# Quick Charge 2.0 daemon\n    setprop persist.usb.hvdcp.detect \"true\"\n/g' init.qcom.rc
sed -i -e "/service hvdcp \/system\/bin\/hvdcp/,/disabled/ s/user root/user root\n    group root/g" init.qcom.rc
sed -i -e "s&#on property:persist.usb.hvdcp.detect=true&on property:persist.usb.hvdcp.detect=true&g" init.qcom.rc
sed -i -e "s/#    start hvdcp/    start hvdcp/g" init.qcom.rc
sed -i -e "s/#on property:persist.usb.hvdcp.detect=false/on property:persist.usb.hvdcp.detect=false/g" init.qcom.rc
sed -i -e "s/#    stop hvdcp/    stop hvdcp/g" init.qcom.rc

# Disable sony_ric
sed -i -e "s/write \/sys\/kernel\/security\/sony_ric\/enable 1/# write \/sys\/kernel\/security\/sony_ric\/enable 0/g" init.sony-platform.rc
sed -i -e "s/mount securityfs securityfs \/sys\/kernel\/security nosuid nodev noexec/# mount securityfs securityfs \/sys\/kernel\/security nosuid nodev noexec/g" init.sony-platform.rc
sed -i -e "s/service ric \/sbin\/ric/service ric \/sbin\/ric\n    disabled/g" init.sony-platform.rc

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

crashtag=`cat crashtag`
devicename=`echo ${crashtag} | sed "s/.*-\([a-zA-Z0-9]*\).*/\1/"`

# Compress ramdisk
find ./* | cpio -o -H newc | gzip -9 > ../../ramdisk$devicename.cpio.gz
