#!/bin/sh
if [ -d work ]; then
    rm -rf ./work
fi

# ELF format (SIN v1 ~ SIN v3)
if [ ! -e kernel.elf ]; then
    if [ -e kernel*.elf ]; then
        mv kernel*.elf kernel.elf
    fi

    if [ -e kernel*.ext4 ]; then
        mv kernel*.ext4 kernel.elf
    fi
fi

# Android image format (SIN v4 ~ )
if [ ! -e kernel.bin ]; then
    if [ -e kernel*.bin ]; then
        mv kernel*.bin kernel.bin
    fi
fi

mkdir work

if [ -e kernel.elf ]; then
	mv kernel.elf work/kernel.sin
	cp -a tools/unpack-kernelsin64.pl work/unpack-kernelsin64.pl
elif [ -e kernel.bin ]; then
	mv kernel.bin work/kernel.bin
fi


cd work

if [ -e kernel.elf ]; then
	chmod 777 unpack-kernelsin64.pl
	./unpack-kernelsin64.pl kernel.sin
elif [ -e kernel.bin ]; then
	../tools/unpackbootimg -i kernel.bin
	mkdir kernel.sin-ramdisk
	mv kernel.bin-ramdisk.gz kernel.sin-ramdisk/kernel.bin-ramdisk.gz
	cd kernel.sin-ramdisk
	gunzip -c kernel.bin-ramdisk.gz | cpio -i
	rm -f kernel.bin-ramdisk.gz
fi

