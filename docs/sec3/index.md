## Building Linux
This step is optional. The generated files by this flow are available in this repository.
The required files are as follows:
- [uImage](../../zybo/BOOT_FS/uImage)
- [zynq-zybo-z7.dtb](../../zybo/BOOT_FS/zynq-zybo-z7.dtb)
- [Debian packages (headers, image, libc)](../../zybo/ROOT_FS/package/)

If you want to build the Linux kernel on your computer, please run the followings:
``` sh
$ apt install build-essential ccache bc bison flex ncurses-dev git u-boot-tools gcc-arm*
$ git clone --depth 1 -b xilinx-v2019.1 https://github.com/Xilinx/linux-xlnx.git linux-xlnx-v2019.1-zybo-z7 && cd linux-xlnx-v2019.1-zybo-z7
$ git checkout -b linux-xlnx-v2019.1-zybo-z7 refs/tags/xilinx-v2019.1
$ sed -i -e 's|bootargs = ""|bootargs = "console=ttyPS0,115200 root=/dev/mmcblk0p2 rw earlyprintk rootfstype=ext4 rootwait devtmpfs.mount=1 uio_pdrv_genirq.of_id=generic-uio earlycon"|g' arch/arm/boot/dts/zynq-zybo-z7.dts
$ patch -p1 < <ROOT OF THIS REPOSITORY>/assets/patch/linux-xlnx-v2019.1-zybo-z7-builddeb.diff
$ git add --update
$ git commit -m "update dts for zybo-z7"
$ git tag -a xilinx-v2019.1-zybo-z7-3 -m "release xilinx-v2019.1-zybo-z7-3"
$ echo 3 > .version
$ make xilinx_zynq_defconfig ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf-
$ patch -p0 < <ROOT OF THIS REPOSITORY>/assets/patch/dot.config.patch
$ ccache make -j<some number> deb-pkg ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- DTC_FLAGS=--symbols
$ make uImage ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- UIMAGE_LOADADDR=0x8000
$ cp arch/arm/boot/uImage <ROOT OF THIS REPOSITORY>/zybo/BOOT_FS
$ cp arch/arm/boot/dts/zynq-zybo-z7.dtb <ROOT OF THIS REPOSITORY>/zybo/BOOT_FS
$ cp ../linux-*.deb <ROOT OF THIS REPOSITORY>/zybo/ROOT_FS/package
```
A shell script to automate this process is provided for your convenience. Install the requirements then run the provided script. Make sure `AD_REFKIT_SAMPLE_SCRIPT_PATH` is set as instructed in the previous step.
``` sh
$ sudo apt install build-essential ccache bc bison flex ncurses-dev git u-boot-tools gcc-arm*
$ sh build_linux.sh
```
 
