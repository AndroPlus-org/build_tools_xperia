#!/system/bin/sh

bb=/sbin/busybox

if [ "$($BB mount | $BB grep rootfs | $BB cut -c 26-27 | $BB grep -c ro)" -eq "1" ]; then
	$BB mount -o remount,rw /;
fi;
if [ "$($BB mount | $BB grep system | $BB grep -c ro)" -eq "1" ]; then
	$BB mount -o remount,rw /system;
fi;

# Disable MP decision
#mount -o remount,rw /system
#$bb mv /system/bin/mpdecision_disabled /system/bin/mpdecision

# create init.d folder
if [ ! -d /system/etc/init.d ]
then
  $bb mkdir /system/etc/init.d
  $bb chown -R root.root /system/etc/init.d
  $bb chmod -R 755 /system/etc/init.d
fi

# start init.d
for FILE in /system/etc/init.d/*; do
   sh $FILE >/dev/null
done;

if [ "$($BB mount | $BB grep system | $BB grep -c rw)" -eq "1" ]; then
	$BB mount -o remount,ro /system;
fi;
