## Prepare microSD
### 1. Format microSD
Make partition with GParted. \
If you have not installed GParted yet, install it.

``` sh
$ sudo apt install gparted debootstrap 
```

Run GParted, and then make partitions on microSD as the followigns.

``` sh
$ sudo gparted
```

- 1st partition : fat16, about 64-128MiB
- 2nd partition : ext4, all of rest

### 2. Prepare rootfs
Run the following commands.

```
# install Ubuntu 18.04 LTS and neessary packages
$ sudo mount /dev/<YOUR SD #2> /mnt # ex. /dev/sdd2
$ sudo debootstrap --foreign --arch armhf bionic /mnt http://ports.ubuntu.com/
$ sudo apt install qemu-user-static
$ sudo cp /usr/bin/qemu-arm-static /mnt/usr/bin/
$ sudo chroot /mnt
I have no name!@ubuntu:# ./debootstrap/debootstrap --second-stage
I have no name!@ubuntu:# passwd
I have no name!@ubuntu:# su
root@ubuntu:# passwd
root@ubuntu:# apt install software-properties-common
root@ubuntu:# add-apt-repository universe && apt update
root@ubuntu:# adduser user
root@ubuntu:# apt install locales ssh chrony libusb-1.0-0-dev
root@ubuntu:# locale-gen en_US.UTF-8
root@ubuntu:# apt install git
root@ubuntu:# git clone -b v1.4.7 https://git.kernel.org/pub/scm/utils/dtc/dtc.git dtc && cd dtc
root@ubuntu:# apt install build-essential
root@ubuntu:# apt install flex bison
root@ubuntu:# make && make HOME=/usr install-bin
root@ubuntu:# cd .. && rm -rf dtc
root@ubuntu:# sed -i -e 's/#PasswordAuthentication/PasswordAuthentication/g' /etc/ssh/sshd_config
root@ubuntu:# sed -i -e 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
root@ubuntu:# sed -i -e 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
root@ubuntu:# echo 'server <available NTP server> iburst' >> /etc/ntp.conf # For example, ntp1.jst.mfeed.ad.jp
root@ubuntu:# systemctl enable chrony
root@ubuntu:# cat <<EOT > /etc/systemd/network/eth0.network
              [Match]
              Name=eth0
              [Network]
              DHCP=ipv4
              EOT
root@ubuntu:# systemctl enable systemd-networkd

# install OpenCV 4.2.0
root@ubuntu:# apt install -y \
              build-essential cmake ccache git pkg-config libgtk-3-dev \
              libavcodec-dev libavformat-dev libswscale-dev libv4l-dev \
              libxvidcore-dev libx264-dev libjpeg-dev libpng-dev libtiff-dev \
              gfortran openexr libatlas-base-dev python3-dev python3-numpy \
              libtbb2 libtbb-dev libdc1394-22-dev
root@ubuntu:# mkdir opencv_build && cd opencv_build
root@ubuntu:# git clone --depth 1 https://github.com/opencv/opencv.git
root@ubuntu:# git clone --depth 1 https://github.com/opencv/opencv_contrib.git
root@ubuntu:# export OPENCV_BUILD_PATH=$(pwd)
root@ubuntu:# cd opencv && mkdir build && cd build
root@ubuntu:# cmake -D CMAKE_BUILD_TYPE=RELEASE \
                    -D CMAKE_INSTALL_PREFIX=/usr/local \
                    -D INSTALL_C_EXAMPLES=ON \
                    -D INSTALL_PYTHON_EXAMPLES=ON \
                    -D OPENCV_GENERATE_PKGCONFIG=ON \
                    -D OPENCV_EXTRA_MODULES_PATH=$(printenv OPENCV_BUILD_PATH)/opencv_contrib/modules \
                    -D BUILD_EXAMPLES=ON ..
root@ubuntu:# ccache make -j<some number>
root@ubuntu:# make install
root@ubuntu:# pkg-config --modversion opencv4
root@ubuntu:# cd ../../../ && rm -rf opencv_build

root@ubuntu:# exit
```

### 3. Prepare bootfs
Copy the following five files into bootfs i.e. 1st partition.

- [BOOT.bin](../../zybo/BOOT_FS/BOOT.bin)
- [uEnv.txt](../../zybo/BOOT_FS/uEnv.txt)
- [uImage](../../zybo/BOOT_FS/uImage)
- [uramdisk.image.gz](../../zybo/BOOT_FS/uramdisk.image.gz)
- [zynq-zybo-z7.dtb](../../zybo/BOOT_FS/zynq-zybo-z7.dtb)

It is able to use the files in `zybo/BOOT_FS` as they are.

#### 3.1 BOOT.bin
`BOOT.bin` is generated from the follow three files.

- FSBL
- bitstream
- u-boot

These are prepared in `zybo/BOOT_FS/bootbin_src`.\
The details of how to build these files are omitted.\
The prepared bit-stream (`hardware.bit`) just blink LEDs.\
The following commands generates `BOOT.bin`.

``` sh
$ cd <ROOT OF THIS REPOSITORY>/zybo/BOOT_FS/bootbin_src
$ bootgen -arch zynq -image build.bif -w -o ../BOOT.bin
```

#### 3.2 uEnv.txt
``` txt
uenvcmd=fatload mmc 0 0x03000000 uImage && fatload mmc 0 0x02A00000 zynq-zybo-z7.dtb && bootm 0x03000000 - 0x02A00000
ethaddr=02:50:10:70:11:A2
```

#### 3.3 uImage
Use the file generated in [Building Linux](../sec3/index.md)

#### 3.4 uramdisk.image.gz
[Build and Modify a Rootfs](https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18842473/Build+and+Modify+a+Rootfs)

#### 3.5 zynq-zybo-z7.dtb
Use the file generated in [Building Linux](../sec3/index.md)
