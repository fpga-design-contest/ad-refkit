## SDカードの準備
### 1. MicroSDカードのフォーマット
GPartedを用いてパーティションの分割・フォーマットを行います。\
インストールされていない場合はパッケージマネージャを用いてインストールしてください。

``` sh
$ sudo apt install gparted
```

GPartedを起動して、MicroSDを指すデバイス指定し、以下のようにパーティションを分けます。

``` sh
$ sudo gparted
```

- 第1パーティション : fat16, 64-128MiB程度
- 第2パーティション : ext4,  残りの全ての領域

### 2. rootfsの用意
以下に示すコマンドを実行して下さい。\
OpenCVのビルドに時間がかかりますので注意して下さい。

``` sh
# install Ubuntu 18.04 LTS and neessary packages
$ sudo mount -o loop /dev/mmcblk0p2 /mnt
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
root@ubuntu:# git clone -b v1.4.7 https://git.kernel.org/pub/scm/utils/dtc/dtc.git dtc && cd dtc
root@ubuntu:# make && make HOME=/usr install-bin
root@ubuntu:# cd .. && rm -rf dtc
root@ubuntu:# sed -i -e 's/#PasswordAuthentication/PasswordAuthentication/g' /etc/ssh/sshd_config
root@ubuntu:# sed -i -e 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
root@ubuntu:# sed -i -e 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
root@ubuntu:# echo 'server <利用可能なNTPサーバ> iburst' >> /etc/ntp.conf # <利用可能なNTPサーバ>の例: ntp1.jst.mfeed.ad.jp
root@ubuntu:# systemctl enable chrony

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
root@ubuntu:# ccache make -j<適当なjob数>
root@ubuntu:# make install
root@ubuntu:# pkg-config --modversion opencv4
root@ubuntu:# cd ../../../ && rm -rf opencv_build
root@ubuntu:# exit
```

### 3. bootfsの用意
以下の5つのファイルをbootfs、つまり、第1パーティションに置きます。

- BOOT.bin
- uEnv.txt
- uImage
- uramdisk.image.gz
- zynq-zybo-z7.dtb

#### 3.1 BOOT.bin
以下に示す3つのファイルを用いて作成します。

- FSBL
- bitstream
- u-boot

これらは`zybo/BOOT_FS/bootbin_src`下に用意しています。\
それぞれのファイルの作成方法は省略します。\
ここに用意しているビットストリームファイル(`hardware.bit`)はLEDを点滅させるだけのものになります。\
`BOOT.bin`は以下のコマンドで生成することが出来ます。

``` sh
$ cd <root path of this repository>/zybo/BOOT_FS/bootbin_src
$ bootgen -arch zynq -image build.bif -w -o ../BOOT.bin
```

#### 3.2 uEnv.txt
``` txt
uenvcmd=fatload mmc 0 0x03000000 uImage && fatload mmc 0 0x02A00000 zynq-zybo-z7.dtb && bootm 0x03000000 - 0x02A00000
ethaddr=02:50:10:70:11:A2
```

#### 3.3 uImage
`Linuxカーネルのビルド`において作成したものを使用してください。

#### 3.4 uramdisk.image.gz
[Build and Modify a Rootfs](https://xilinx-wiki.atlassian.net/wiki/spaces/A/pages/18842473/Build+and+Modify+a+Rootfs)

#### 3.5 zynq-zybo-z7.dtb
`Linuxカーネルのビルド`において作成したものを使用してください。
