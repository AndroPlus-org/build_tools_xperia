#!/bootrec/busybox sh

########################################
# Sony FOTAKernel Recovery Boot Script #
#    Author: github.com/jackfagner     #
#             Version: 1.2             #
########################################

# Disable printing/echo of commands
set +x

############
# SETTINGS #
############

REAL_INIT="/init.real"

DEVICE_CODENAME="PLEASECHANGETHIS"

DEV_FOTA_NODE="/dev/block/mmcblk0p48 b 259 16"
DEV_FOTA="/dev/block/mmcblk0p48"

DEV_FOTA_NODE_DORA="/dev/block/mmcblk0p45 b 259 13"
DEV_FOTA_DORA="/dev/block/mmcblk0p45"

DEV_FOTA_NODE_KUGO="/dev/block/mmcblk0p46 b 259 14"
DEV_FOTA_KUGO="/dev/block/mmcblk0p46"

DEV_FOTA_NODE_KAGURA="/dev/block/mmcblk0p48 b 259 16"
DEV_FOTA_KAGURA="/dev/block/mmcblk0p48"

LOG_FILE="/bootrec/boot-log.txt"
RECOVERY_CPIO="/bootrec/recovery.cpio"

TOUCH_EVENT="/dev/input/event5"
KEY_EVENT_DELAY=3
WARMBOOT_RECOVERY=0x77665502

LED_RED="/sys/class/leds/led:rgb_red/brightness"
LED_GREEN="/sys/class/leds/led:rgb_green/brightness"
LED_BLUE="/sys/class/leds/led:rgb_blue/brightness"

LED_RED_KUGO="/sys/class/leds/as3668:red/brightness"
LED_GREEN_KUGO="/sys/class/leds/as3668:green/brightness"
LED_BLUE_KUGO="/sys/class/leds/as3668:blue/brightness"

if [ ${DEVICE_CODENAME} = "dora" ]; then
  DEV_FOTA_NODE=${DEV_FOTA_NODE_DORA}
  DEV_FOTA=${DEV_FOTA_DORA}
fi

if [ ${DEVICE_CODENAME} = "kagura" ]; then
  DEV_FOTA_NODE=${DEV_FOTA_NODE_KAGURA}
  DEV_FOTA=${DEV_FOTA_KAGURA}
fi

if [ ${DEVICE_CODENAME} = "kugo" ]; then
  LED_RED=${LED_RED_KUGO}
  LED_GREEN=${LED_GREEN_KUGO}
  LED_BLUE=${LED_BLUE_KUGO}
  DEV_FOTA_NODE=${DEV_FOTA_NODE_KUGO}
  DEV_FOTA=${DEV_FOTA_KUGO}
fi

############
#   CODE   #
############

# Save current PATH variable, then change it
_PATH="$PATH"
export PATH=/bootrec:/sbin

# Use root as base dir
busybox cd /

# Log current date/time
busybox date >> ${LOG_FILE}

# Redirect stdout and stderr to log file
exec >> ${LOG_FILE} 2>&1

# Re-enable printing commands
set -x

# Delete this script
busybox rm -f /init

# Create directories
busybox mkdir -m 755 -p /dev/input
busybox mkdir -m 555 -p /proc
busybox mkdir -m 755 -p /sys

# Create device nodes
# Per linux Documentation/devices.txt
for i in $(busybox seq 0 12); do
	busybox mknod -m 600 /dev/input/event${i} c 13 $(busybox expr 64 + ${i})
done
busybox mknod -m 666 /dev/null c 1 3

# Mount filesystems
busybox mount -t proc proc /proc
busybox mount -t sysfs sysfs /sys

# Methods for controlling LED
led_blue() {
  busybox echo  13 > ${LED_RED}
  busybox echo  59 > ${LED_GREEN}
  busybox echo  95 > ${LED_BLUE}
}
led_amber() {
  busybox echo 255 > ${LED_RED}
  busybox echo 255 > ${LED_GREEN}
  busybox echo   0 > ${LED_BLUE}
}
led_orange() {
  busybox echo 255 > ${LED_RED}
  busybox echo 100 > ${LED_GREEN}
  busybox echo   0 > ${LED_BLUE}
}
led_off() {
  busybox echo   0 > ${LED_RED}
  busybox echo   0 > ${LED_GREEN}
  busybox echo   0 > ${LED_BLUE}
}

# Start listening for key events
#busybox cat ${TOUCH_EVENT} > /dev/touchcheck&

# Set LED to blue to indicate it's time to press screen
#led_blue

# Sleep for a while to collect key events
#busybox sleep 2

# Data collected, kill key event collector
#busybox pkill -f "cat ${TOUCH_EVENT}"

# Set LED to amber to indicate it's time to press keys
led_amber

# Keycheck will exit with code 42 if vol up/down is pressed
busybox timeout -t ${KEY_EVENT_DELAY} keycheck

# Check if we detected volume key pressing or the user rebooted into recovery mode
if [ $? -eq 42 ] || [ -s /dev/touchcheck ] || busybox grep -q warmboot=${WARMBOOT_RECOVERY} /proc/cmdline; then
  echo "Entering Recovery Mode" >> ${LOG_FILE}

  # Set LED to orange to indicate recovery mode
  led_orange

  # Create directory and device node for FOTA partition
  busybox mkdir -m 755 -p /dev/block
  busybox mknod -m 600 ${DEV_FOTA_NODE}

  # Make sure root is in read-write mode
  busybox mount -o remount,rw /

  # extract_elf_ramdisk needs sh in PATH
  # FIXME: unconfirmed! We can probably skip sh
  busybox ln -sf /bootrec/busybox /bootrec/sh

  # Extract recovery ramdisk
  extract_elf_ramdisk -i ${DEV_FOTA} -o ${RECOVERY_CPIO} -t /

  # Remove sh again (if we created it)
  busybox rm -f /bootrec/sh

  # Clean up rc scripts in root to avoid problems
  busybox rm -f /init*.rc /init*.sh

  # Unpack ramdisk to root
  busybox cpio -i -u < ${RECOVERY_CPIO}

  # Delete recovery ramdisk
  busybox rm -f ${RECOVERY_CPIO}
else
  echo "Booting Normally" >> ${LOG_FILE}

  # Move real init script into position
  busybox mv ${REAL_INIT} /init
fi

# Clean up, start with turning LED off
led_off

# Remove folders and devices
busybox umount /proc
busybox umount /sys
busybox rm -rf /dev/*

# Remove dangerous files to avoid security problems
busybox rm -f /bootrec/extract_elf_ramdisk /bootrec/init.sh /bootrec/busybox /bootrec/keycheck

# Reset PATH
export PATH="${_PATH}"

# All done, now boot
exec /init $@
