#!/sbin/busybox sh

bb=/sbin/busybox;

$bb mount -o remount,rw /system
mount -o remount,rw /system

# Set TCP westwood
$bb echo "westwood" > /proc/sys/net/ipv4/tcp_congestion_control

# Enable and configure intelli thermal
$bb echo "Y" > /sys/module/msm_thermal_v2/parameters/enabled
$bb echo "1" > /sys/module/msm_thermal_v2/core_control/enabled
$bb echo "65" > /sys/module/msm_thermal_v2/parameters/core_limit_temp_degC
$bb echo "70" > /sys/module/msm_thermal_v2/parameters/limit_temp_degC
$bb echo "250" > /sys/module/msm_thermal_v2/parameters/poll_ms
$bb echo "0" > /sys/module/msm_thermal_v2/vdd_restriction/enabled
$bb echo "12" > /sys/module/msm_thermal_v2/parameters/core_control_mask
$bb echo "15" > /sys/module/msm_thermal_v2/parameters/freq_control_mask

# Enable intelli_plug
$bb echo "1" > /sys/kernel/intelli_plug/intelli_plug_active

mount -o ro,remount /system

