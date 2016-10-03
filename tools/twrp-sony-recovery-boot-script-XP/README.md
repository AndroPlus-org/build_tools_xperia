# Sony recovery boot script

This script will chain load an Android recovery from the FOTAKernel partition.

## Instructions to kernel developer

* Put **bootrec** folder in the root of your ramdisk.
* If not on ARM64, replace **busybox** and **extract_elf_ramdisk** binaries.
* Move your **/init** to **/init.real**
* Symlink **/init** to **/bootrec/init.sh**
* ???
* Profit.

The **init.sh** script is setup for Xperia Tone Platform.
On other devices you might have to change some paths at the top of the script file.

Modded by AndroPlus.
