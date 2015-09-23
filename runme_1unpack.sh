#!/bin/sh
if [ -d work ]
then
rm -rf ./work
fi

mkdir work
mv kernel.sin work/kernel.sin
cp tools/unpack-kernelsin.pl work/unpack-kernelsin.pl
cd work
chmod 777 unpack-kernelsin.pl
./unpack-kernelsin.pl kernel.sin
