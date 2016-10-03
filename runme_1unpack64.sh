#!/bin/sh
if [ -d work ]; then
    rm -rf ./work
fi

if [ ! -e kernel.elf ]; then
    if [ -e kernel*.elf ]; then
        mv kernel*.elf kernel.elf
    fi

    if [ -e kernel*.ext4 ]; then
        mv kernel*.ext4 kernel.elf
    fi
fi

mkdir work
mv kernel.elf work/kernel.sin
cp tools/unpack-kernelsin64.pl work/unpack-kernelsin64.pl
cd work
chmod 777 unpack-kernelsin64.pl
./unpack-kernelsin64.pl kernel.sin
