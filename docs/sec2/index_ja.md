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

このスクリプトを実行すると、`zybo/ROOT_FS/firmware`にbinファイルが作成されます。
