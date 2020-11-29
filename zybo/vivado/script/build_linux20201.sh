#!/bin/sh

# sudo apt install build-essential ccache bc bison flex ncurses-dev git u-boot-tools gcc-arm*


if [ -n "$AD_REFKIT_SAMPLE_SCRIPT_PATH" ];
then
    cd $AD_REFKIT_SAMPLE_SCRIPT_PATH/../../..
    AD_REFKIT_ROOT=$(pwd)
	mkdir linux && cd linux
	git clone --depth 1 -b xilinx-v2020.1 https://github.com/Xilinx/linux-xlnx.git linux-xlnx-v2020.1-zybo-z7 && cd linux-xlnx-v2020.1-zybo-z7
	git checkout -b linux-xlnx-v2020.1-zybo-z7 refs/tags/xilinx-v2020.1
	sed -i -e 's|bootargs = ""|bootargs = "console=ttyPS0,115200 root=/dev/mmcblk0p2 rw earlyprintk rootfstype=ext4 rootwait devtmpfs.mount=1 uio_pdrv_genirq.of_id=generic-uio earlycon"|g' arch/arm/boot/dts/zynq-zybo-z7.dts
	patch -p1 < $AD_REFKIT_ROOT/assets/patch/linux-xlnx-v2019.1-zybo-z7-builddeb.diff
	git add --update
	git commit -m "update dts for zybo-z7"
	git tag -a xilinx-v2020.1-zybo-z7-5 -m "release xilinx-v2020.1-zybo-z7-5"
	echo 5 > .version
	make xilinx_zynq_defconfig ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
	patch -p0 < $AD_REFKIT_ROOT/assets/patch/dot.config20201.patch
	ccache make -j$(nproc) deb-pkg ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- DTC_FLAGS=--symbols
	make uImage ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- UIMAGE_LOADADDR=0x8000
	cp arch/arm/boot/uImage $AD_REFKIT_ROOT/zybo/BOOT_FS
	cp arch/arm/boot/dts/zynq-zybo-z7.dtb $AD_REFKIT_ROOT/zybo/BOOT_FS
	cp ../linux-*.deb $AD_REFKIT_ROOT/zybo/ROOT_FS/package
    
else
    echo "Please set environment value like this."
    echo "$ cd <ROOT OF THIS REPOSITORY>/zybo/vivado/script"
    echo "$ export AD_REFKIT_SAMPLE_SCRIPT_PATH=\$(pwd)"
fi
