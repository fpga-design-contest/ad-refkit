#!/bin/sh
SCRIPT_DIR=$(cd $(dirname $0); pwd)
DTO_DIR=/sys/kernel/config/device-tree/overlays
echo "SCRIPT_DIR:" $SCRIPT_DIR

# カーネルモジュールのインストール
lsmod | grep "v4l2"
if [ $? = 0 ]; then
    rmmod v4l2
fi
cd $SCRIPT_DIR/driver/v4l2/build
make
insmod v4l2.ko

# bitstreamの反映
mkdir -p /lib/firmware
cp $SCRIPT_DIR/firmware/fpga.bin /lib/firmware

# Device Tree Overlay
## fpga congigurarion
mkdir -p $DTO_DIR/fpga
dtc -I dts -O dtb -o $SCRIPT_DIR/dts/fpga.dtb $SCRIPT_DIR/dts/fpga.dts
cp $SCRIPT_DIR/dts/fpga.dtb $DTO_DIR/fpga/dtbo

## motor-gpio
mkdir -p $DTO_DIR/motor-gpio
dtc -I dts -O dtb -o $SCRIPT_DIR/dts/motor-gpio.dtb $SCRIPT_DIR/dts/motor-gpio.dts
cp $SCRIPT_DIR/dts/motor-gpio.dtb $DTO_DIR/motor-gpio/dtbo

## preimproc
mkdir -p $DTO_DIR/preimproc
dtc -I dts -O dtb -o $SCRIPT_DIR/dts/preimproc.dtb $SCRIPT_DIR/dts/preimproc.dts
cp $SCRIPT_DIR/dts/preimproc.dtb $DTO_DIR/preimproc/dtbo

## i2c
mkdir -p $DTO_DIR/i2c
dtc -I dts -O dtb -o $SCRIPT_DIR/dts/i2c.dtb $SCRIPT_DIR/dts/i2c.dts
cp $SCRIPT_DIR/dts/i2c.dtb $DTO_DIR/i2c/dtbo

## v4l2
mkdir -p $DTO_DIR/v4l2
dtc -I dts -O dtb -o $SCRIPT_DIR/dts/v4l2.dtb $SCRIPT_DIR/dts/v4l2.dts
cp $SCRIPT_DIR/dts/v4l2.dtb $DTO_DIR/v4l2/dtbo

# 共有ライブラリのbuild
cd $SCRIPT_DIR/lib
sh build_all.sh
