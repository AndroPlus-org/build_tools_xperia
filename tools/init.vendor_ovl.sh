#!/system/bin/sh
OVERLAY_PATH=$1
TARGET=/system/vendor

unpack() {
	for file in $1; do
		[ -e $file ] && $OVERLAY_PATH/bin/busybox unxz $file && chmod $2 ${file%.*}
	done
}

for dir in $OVERLAY_PATH/*; do
  [ -d $dir ] && for file in $TARGET/${dir##*/}/*; do
	ln -s $file $dir/${file##*/}
  done
done

for file in $TARGET/*; do
  ovl_file=$OVERLAY_PATH/${file##*/}
  [ ! -e $ovl_file ] && ln -s $file $ovl_file
done

#SuperSu requires a copy of app_process with context system_file
#other tools with app_process do not work as they would transition into zygote
if [ -e  $OVERLAY_PATH/bin/su ]; then
	cp /system/bin/app_process $OVERLAY_PATH/bin/app_process
	chmod 0755 $OVERLAY_PATH/bin/app_process
fi

#Create busybox links only for tools which are not in /system/bin
#as /vendor/bin is usually before in the PATH
if [ -e $OVERLAY_PATH/bin/busybox ]; then
	mkdir $OVERLAY_PATH/bb
	$OVERLAY_PATH/bin/busybox --install -s $OVERLAY_PATH/bb
	for file in $OVERLAY_PATH/bb/*; do
		[ -e /system/bin/${file##*/} ] && rm $file
		[ -e /system/sbin/${file##*/} ] && rm $file
		[ -e /system/xbin/${file##*/} ] && rm $file
		[ -e $OVERLAY_PATH/bin/${file##*/} ] && rm $file
		[ -e /sbin/${file##*/} ] && rm $file
	done
	mv $OVERLAY_PATH/bb/* $OVERLAY_PATH/bin/
	rmdir $OVERLAY_PATH/bb
fi

unpack "$OVERLAY_PATH/bin/*.xz"   0755
unpack "$OVERLAY_PATH/lib/*.xz"   0644
unpack "$OVERLAY_PATH/lib64/*.xz" 0644
unpack "$OVERLAY_PATH/app/*/*.xz" 0644

for file in /vendor/lib/modules/*; do
	[ -e $file ] && insmod $file
done

exit 0
