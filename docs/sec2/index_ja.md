## ビットストリームの生成
Block Designを生成するスクリプトを実行します。

``` sh
$ cd <ROOT OF THIS REPOSITORY>/zybo/vivado/script
$ sh setup_bd.sh
```

スクリプトの実行が完了したら、VivadoのGUI上で`Generate Bitstream`を実行して下さい。\
Bitstreamの生成が完了したら、FPGA Regionによる動的読み込みに対応するためにbitファイルをbinファイルに変換します。

``` sh
$ cd <ROOT OF THIS REPOSITORY>/zybo/vivado/script
$ sudo chmod u+x fpga-bit2bin.py
$ sh create_bitstream_bin.sh
```

このスクリプトを実行すると、`zybo/ROOT_FS/firmware`にbinファイルが作成されます。\
次に、以下の手順に従ってXilinx SDKを起動し、BSPを作成してください。

1. [Vivado] File -> Export -> Export Hardware
2. [Vivado] File -> Launch SDK
3. [Xilinx SDK] File -> New -> Board Support Package

`standalone_bsp_0`が作成されたことを確認してください。\
作成されたBSPをコピーします。

``` sh
$ cp -R <ROOT OF THIS REPOSITORY>/zybo/vivado/prj/ad_refkit/ad_refkit.sdk/standalone_bsp_0/ps7_cortexa9_0 \
        <ROOT OF THIS REPOSITORY>/zybo/ROOT_FS/zynq_bsp
```
