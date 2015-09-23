#!/bin/sh
if [ -d work ]
then
rm -rf ./work
fi

mkdir work
mv kernel.elf work/kernel.sin
cp tools/unpack-kernelsin64.pl work/unpack-kernelsin64.pl
cd work
chmod 777 unpack-kernelsin64.pl
./unpack-kernelsin64.pl kernel.sin
