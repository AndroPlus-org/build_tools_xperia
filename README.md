Xperiaのカーネルをビルドするために必要な、ramdiskを作るためのツールです。  
runme_2repack_mod.shで色々編集しているので適宜変えてください。  

Xperia Z3シリーズ (shinano) までの場合  
1. kernel.sinをこのディレクトリにコピー  
2. runme_1unpack.shを実行 (ramdiskの中身を編集したければwork/kernel.sin-ramdiskディレクトリで編集する)  
3. runme_2repack_mod.shを実行  

Xperia Z4リーズ (kitakami) 以降の場合  
1. Flashtoolなどでkernel.sinをextractし、kernel.elfをこのディレクトリにコピー  
2. runme_1unpack64.shを実行 (ramdiskの中身を編集したければwork/kernel.sin-ramdiskディレクトリで編集する)  
3. runme_2repack_mod64.shを実行  

## F2FS対応
1. init.target.rcの編集

```ruby:init.target.rc
    start fsckwait

    # Generate proper fstab
    exec /sbin/genfstab.rhine

    mount_all fstab.qcom
    
``` 

2. genfstab.rhineを/sbinにコピー
3. fstab.qcomを削除

