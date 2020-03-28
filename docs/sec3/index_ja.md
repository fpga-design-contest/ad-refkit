## Linuxカーネルのビルド
ここに示す手順はスキップして構いません。\
ここに示す手順によって得られるファイルは以下の通りです。

- uImage
- zynq-zybo-z7.dtb
- 各種debパッケージ(headers, image, libc)

これらはリポジトリ上に既に用意されています。\
新たに用意する場合は以下に従ってください。

``` sh
$ apt install build-essential ccache bc bison flex ncurses-dev git
$ git clone --depth 1 -b xilinx-v2019.1 https://github.com/Xilinx/linux-xlnx.git linux-xlnx-v2019.1-zybo-z7 && cd linux-xlnx-v2019.1-zybo-z7
$ git checkout -b linux-xlnx-v2019.1-zybo-z7 refs/tags/xilinx-v2019.1
$ sed -i -e 's/bootargs = ""/bootargs = "console=ttyPS0,115200 root=/dev/mmcblk0p2 rw earlyprintk rootfstype=ext4 rootwait devtmpfs.mount=1 uio_pdrv_genirq.of_id=generic-uio earlycon"/g' arch/arm/boot/dts/zynq-zybo-z7.dts
$ patch -p0 < <ROOT OF THIS REPOSITORY>/assets/patch/linux-xlnx-v2019.1-zybo-z7-builddeb.diff
$ git add --update
$ git commit -m "update dts for zybo-z7"
$ git tag -a xilinx-v2019.1-zybo-z7-3 -m "release xilinx-v2019.1-zybo-z7-3"
$ echo 3 > .version
$ make xilinx_zynq_defconfig ARCH=arm CROSS_COMPILE=arm-linux-gnueabi-
$ ccache make -j<適当なjob数> deb-pkg ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- DTC_FLAGS=--symbols
$ make uImage ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- UIMAGE_LOADADDR=0x8000
$ cp arch/arm/boot/uImage <ROOT OF THIS REPOSITORY>/zybo/BOOT_FS
$ cp arch/arm/boot/dts/zynq-zybo-z7.dtb <ROOT OF THIS REPOSITORY>/zybo/BOOT_FS
$ cp ../linux-*.deb <ROOT OF THIS REPOSITORY>/zybo/ROOT_FS/package
```
