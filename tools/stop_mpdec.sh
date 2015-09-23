#!/sbin/busybox sh

bb=/sbin/busybox;

# Stop MP decision at boot
stop thermald
stop mpdecision

$bb mount -o remount,rw /system

# Disable MP decision
mount -o remount,rw /system
$bb mv /system/bin/mpdecision /system/bin/mpdecision_disabled

# create init.d folder
if [ ! -d /system/etc/init.d ]
then
  $bb echo "Making init.d Directory ..."
  $bb mkdir /system/etc/init.d
  $bb chown -R root.root /system/etc/init.d
  $bb chmod -R 755 /system/etc/init.d
else
fi

$bb mount -o ro,remount /system

