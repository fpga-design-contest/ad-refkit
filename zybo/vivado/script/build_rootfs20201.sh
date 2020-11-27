#!/bin/sh

#sudo apt install qemu-user-static debootstrap


if [ -n "$AD_REFKIT_SAMPLE_SCRIPT_PATH" ];
then
    cd $AD_REFKIT_SAMPLE_SCRIPT_PATH/../../..


	mkdir microsd; cd microsd
	export WORKDIR=$(pwd)
	sudo qemu-debootstrap --foreign --arch armhf bionic $WORKDIR http://ports.ubuntu.com/ 
	sudo cp -r ../zybo/ROOT_FS/* root/
	sudo cp /usr/bin/qemu-arm-static $WORKDIR/usr/bin/
	sudo chroot $WORKDIR /bin/bash <<"EOT"
	./debootstrap/debootstrap --second-stage
	apt install -y software-properties-common
	add-apt-repository universe && apt update
	export LANGUAGE=en_US.UTF-8
	export LANG=en_US.UTF-8
	export LC_ALL=en_US.UTF-8
	apt install -y locales ssh chrony libusb-1.0-0-dev ntpdate bc
	locale-gen en_US.UTF-8
	adduser --disabled-password --gecos "" user
	apt install -y git
	git clone -b v1.4.7 https://git.kernel.org/pub/scm/utils/dtc/dtc.git dtc && cd dtc
	apt install -y build-essential flex bison
	make && make HOME=/usr install-bin
	cd .. && rm -rf dtc
	sed -i -e 's/#PasswordAuthentication/PasswordAuthentication/g' /etc/ssh/sshd_config
	sed -i -e 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/g' /etc/ssh/sshd_config
	sed -i -e 's/AcceptEnv/#AcceptEnv/g' /etc/ssh/sshd_config
	echo 'pool 0.jp.pool.ntp.org iburst' >> /etc/ntp.conf 
	systemctl enable chrony
	echo "[Match]
Name=eth0
[Network]
DHCP=ipv4" >> /etc/systemd/network/eth0.network
	systemctl enable systemd-networkd
	apt install -y \
              build-essential cmake ccache git pkg-config libgtk-3-dev \
              libavcodec-dev libavformat-dev libswscale-dev libv4l-dev \
              libxvidcore-dev libx264-dev libjpeg-dev libpng-dev libtiff-dev \
              gfortran openexr libatlas-base-dev python3-dev python3-numpy \
              libtbb2 libtbb-dev libdc1394-22-dev
	apt install -y wireless-tools rfkill wpasupplicant linux-firmware libssl-dev usbutils
	cd /root
	git clone https://github.com/lwfinger/rtl8188eu.git
	echo "root:ad-refkit" | chpasswd
	NEW_HOSTNAME="ad-refkit"
	CUR_HOSTNAME=$(hostname)
	hostnamectl set-hostname $NEW_HOSTNAME
	hostname $NEW_HOSTNAME
	sed -i "s/$CUR_HOSTNAME/$NEW_HOSTNAME/g" /etc/hosts
	sed -i "s/$CUR_HOSTNAME/$NEW_HOSTNAME/g" /etc/hostname
	apt install -y rsync u-boot-tools
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
        cp ../linux-*.deb /root/package

	exit
EOT
        sudo cp linux/linux-xlnx-v2020.1-zybo-z7/arch/arm/boot/uImage $AD_REFKIT_ROOT/zybo/BOOT_FS
        cp linux/linux-xlnx-v2020.1-zybo-z7/arch/arm/boot/dts/zynq-zybo-z7.dtb $AD_REFKIT_ROOT/zybo/BOOT_FS
	
 
else
    echo "Please set environment value like this."
    echo "$ cd <ROOT OF THIS REPOSITORY>/zybo/vivado/script"
    echo "$ export AD_REFKIT_SAMPLE_SCRIPT_PATH=\$(pwd)"
fi
