## Prepare microSD
### 1. Format the MicroSD Card
Make partition with GParted. \
If you do not have GParted installed yet, please install it. Also, debootstrap is required to create a basic debian filesystem on the MicroSD.

``` sh
$ sudo apt install gparted debootstrap 
```

Run GParted, and then make two partitions on the MicroSD as follows:

``` sh
$ sudo gparted
```

- 1st partition : fat16, about 64-128MiB
- 2nd partition : ext4, all of rest

### 2. Prepare rootfs
The next step is building the debian root filesystem for the FPGA board. There are two ways to achieve this: building the entire filesystem on host PC, then copy the resulting files to the MicroSD, or mount the MicroSD and build the filesystem directly on the MicroSD. The latter is considerably slower than the former.

To achieve this, we will create a new chroot-ed directory for the debootstrap to work, then set the architecture of the filesystem to ARM. QEMU will be used to run the chroot-ed ARM filesystem on your PC. As the debootstrap completes its task, we will then install and configure the system as well as compiling OpenCV. The OpenCV compilation might take few hours depending on your PC.


#### Building rootfs directly on the MicroSD

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
root@ubuntu:# apt install build-essential flex bison
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
root@ubuntu:# ccache make -j<some number> # 4-5 hours, depends on your environment
root@ubuntu:# make install
root@ubuntu:# pkg-config --modversion opencv4
root@ubuntu:# cd ../../../ && rm -rf opencv_build
root@ubuntu:# apt install -y wireless-tools rfkill wpasupplicant linux-firmware libssl-dev usbutils
root@ubuntu:# cd /root
root@ubuntu:# git clone https://github.com/lwfinger/rtl8188eu.git
root@ubuntu:# exit
I have no name!@ubuntu:# exit
$ sync; sync; sync
$ sudo umount /mnt
$ sudo eject /dev/<YOUR SD> /mnt # ex. /dev/sdd
```

#### Building rootfs on your host PC and copy the files to MicroSD

```
$ mkdir <WORKING DIRECTORY>; cd <WORKING DIRECTORY> # ~/microsd
$ export WORKDIR=$(pwd)
$ sudo debootstrap --foreign --arch armhf bionic $WORKDIR http://ports.ubuntu.com/ 
$ sudo apt install qemu-user-static
$ sudo cp /usr/bin/qemu-arm-static $WORKDIR/usr/bin/
$ sudo chroot $WORKDIR
I have no name!@ubuntu:# ./debootstrap/debootstrap --second-stage
I have no name!@ubuntu:# passwd
I have no name!@ubuntu:# su
root@ubuntu:# passwd
root@ubuntu:# apt install -y software-properties-common
root@ubuntu:# add-apt-repository universe && apt update
root@ubuntu:# adduser user
root@ubuntu:# apt install -y locales ssh chrony libusb-1.0-0-dev ntpdate bc
root@ubuntu:# locale-gen en_US.UTF-8
root@ubuntu:# apt install -y git
root@ubuntu:# git clone -b v1.4.7 https://git.kernel.org/pub/scm/utils/dtc/dtc.git dtc && cd dtc
root@ubuntu:# apt install -y build-essential flex bison
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
root@ubuntu:# ccache make -j<some number> # 2-3 hours, depends on your environment
root@ubuntu:# make install
root@ubuntu:# pkg-config --modversion opencv4
root@ubuntu:# cd ../../../ && rm -rf opencv_build
root@ubuntu:# apt install -y wireless-tools rfkill wpasupplicant linux-firmware libssl-dev usbutils
root@ubuntu:# cd /root
root@ubuntu:# git clone https://github.com/lwfinger/rtl8188eu.git
root@ubuntu:# exit
I have no name!@ubuntu:# exit
$ sudo mount /dev/<YOUR SD #2> /mnt # ex. /dev/sdd2
$ cd $WORKDIR
$ sudo tar cpvf - * | sudo tar xpvf - -C /mnt
$ sync; sync; sync
$ sudo umount /mnt
$ sudo eject /dev/<YOUR SD> /mnt # ex. /dev/sdd
```

### 3. Prepare bootfs
Copy the following five files into bootfs i.e. 1st partition.

- [BOOT.bin](../../zybo/BOOT_FS/BOOT.bin)
- [uEnv.txt](../../zybo/BOOT_FS/uEnv.txt)
- [uImage](../../zybo/BOOT_FS/uImage)
- [uramdisk.image.gz](../../zybo/BOOT_FS/uramdisk.image.gz)
- [zynq-zybo-z7.dtb](../../zybo/BOOT_FS/zynq-zybo-z7.dtb)

We can use files generated in [Building Linux](../sec3/index.md) or use files in `zybo/BOOT_FS` as they are.

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
