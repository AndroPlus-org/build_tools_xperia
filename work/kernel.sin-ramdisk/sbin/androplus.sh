#!/sbin/busybox sh

bb=/sbin/busybox;

$bb mount -o remount,rw /system

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

$bb mount -o ro,remount /system

chmod 777 /vender/bin/touch_fusion
/vender/bin/touch_fusion
