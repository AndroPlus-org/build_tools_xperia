This is tool to unpack and pack ramdisk image for Xperia devices.  
Please change runme_2repack_mod.sh as you like.  

## How to clone
git clone --recursive https://github.com/AndroPlus-org/build_tools_xperia.git  

## How to use
Xperia Z3 (shinano) and previous platform  
1. Copy kernel.sin to this dir  
2. Run runme_1unpack.sh (Edit contents of work/kernel.sin-ramdisk dir if you want)  
3. Run runme_2repack_mod.sh to pack  

Xperia Z3+/Z4 (kitakami) or later  
1. Extract kernel.sin by using Flashtool (Tools -> Sin Editor -> Extract Data) or UnSIN, then copy kernel.elf to this dir  
2. Run runme_1unpack64.sh (Edit contents of work/kernel.sin-ramdisk dir if you want)  
3. Run runme_2repack_mod64.sh to pack  
***
Xperiaのカーネルをビルドするために必要な、ramdiskを作るためのツールです。  
runme_2repack_mod.shで色々編集しているので適宜変えてください。  

## 使用方法
Xperia Z3シリーズ (shinano) までの場合  
1. kernel.sinをこのディレクトリにコピー  
2. runme_1unpack.shを実行 (ramdiskの中身を編集したければwork/kernel.sin-ramdiskディレクトリで編集する)  
3. runme_2repack_mod.shを実行  

Xperia Z3+/Z4シリーズ (kitakami) 以降の場合  
1. Flashtool (Tools -> Sin Editor -> Extract Data)、UnSINなどでkernel.sinをextractし、kernel.elfをこのディレクトリにコピー  
2. runme_1unpack64.shを実行 (ramdiskの中身を編集したければwork/kernel.sin-ramdiskディレクトリで編集する)  
3. runme_2repack_mod64.shを実行  

## F2FS対応メモ
1. init.target.rcの編集

```ruby:init.target.rc
    start fsckwait

    # Generate proper fstab
    exec /sbin/genfstab.rhine

    mount_all fstab.qcom
    
``` 

2. genfstab.rhineを/sbinにコピー
3. fstab.qcomを削除

