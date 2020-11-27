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
	mkdir opencv_build && cd opencv_build
	git clone --depth 1 https://github.com/opencv/opencv.git
	git clone --depth 1 https://github.com/opencv/opencv_contrib.git
	export OPENCV_BUILD_PATH=$(pwd)
	cd opencv && mkdir build && cd build
	cmake -D CMAKE_BUILD_TYPE=RELEASE \
               -D CMAKE_INSTALL_PREFIX=/usr/local \
               -D INSTALL_C_EXAMPLES=ON \
               -D INSTALL_PYTHON_EXAMPLES=ON \
               -D OPENCV_GENERATE_PKGCONFIG=ON \
               -D OPENCV_EXTRA_MODULES_PATH=$(printenv OPENCV_BUILD_PATH)/opencv_contrib/modules \
               -D BUILD_EXAMPLES=ON ..
	ccache make -j$(nproc)
	make install -j$(nproc)
	pkg-config --modversion opencv4
	cd ../../../ && rm -rf opencv_build
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
	exit
EOT
	
 
else
    echo "Please set environment value like this."
    echo "$ cd <ROOT OF THIS REPOSITORY>/zybo/vivado/script"
    echo "$ export AD_REFKIT_SAMPLE_SCRIPT_PATH=\$(pwd)"
fi
