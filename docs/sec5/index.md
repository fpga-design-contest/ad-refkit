## Run application
Connect ZYBO Z7-20 and host computer with Ethernet cable and USB cable.\
And then, insert microSD card into ZYBO Z7-20 and turn on the power switch.\
Access to ZYBO Z7-20 via USB tty and assign a IP-address to eth0.

### Setup
Set IP-address on ZYBO Z7-20:

``` sh
# ip addr add <IP ADDRESS> dev eth0 # ex. ip addr add 192.168.2.100/24 dev eth0
```

After that, transfer all of the files in `zybo/ROOT_FS` into `/root` on ZYBO Z7-20.

``` sh
$ scp -r <ROOT OF THIS REPOSITORY>/zybo/ROOT_FS/* root@<IP ADDRESS>:/root
```

### Login and setup kernel-modules and headers


Login to Z7-20 as root by SSH.

``` sh
$ ssh -X root@<IP ADDRESS>
```

In case that your ZYBO Z7-20 cannot connect the Internet, set date by your hand.

```
# date -s "10 JUL 2020 19:40:00" # an example
```

At your first login, run the following commands to install Debian packages.

``` sh
$ cd ~/package
$ dpkg -i linux-image-4.19.0-xilinx_4.19.0-xilinx-4_armhf.deb
$ dpkg -i linux-headers-4.19.0-xilinx_4.19.0-xilinx-4_armhf.deb
$ dpkg -i linux-libc-dev_4.19.0-xilinx-4_armhf.deb
```

### Setup WiFi (if necessary)

Compile the driver on ZYBO Z7-20:

```
# cd /root/rtl8188eu
# git checkout v5.2.2.4
# make
# make install
```

After building and installation of the driver, the dirver module will be loaded at the WiFi adapter connected as the following.

```
# lsmod 
Module                  Size  Used by
8188eu               1392640  0
v4l2                   32768  0
sha256_generic         20480  0
cfg80211              249856  1 8188eu
```

You can find your adapter by `iwconfig`.

```
# iwconfig 
eth0      no wireless extensions.

lo        no wireless extensions.

sit0      no wireless extensions.

wlxd037451c9c81  IEEE 802.11  ESSID:off/any  
          Mode:Managed  Access Point: Not-Associated   Tx-Power=12 dBm   
          Retry short limit:7   RTS thr:off   Fragment thr:off
          Encryption key:off
          Power Management:on
```

You can make a setup of WiFi connection by the following instructions.

1. Generate `wpa_supplicant.conf`

```
# wpa_passphrase <YOUR SSID> <YOUR PASSWORD> > /etc/wpa_supplicant/wpa_supplicant.conf
```

2. Add some parameters in `/etc/wpa_supplicant/wpa_supplicant.conf`

```
        proto=RSN
        key_mgmt=WPA-PSK
        pairwise=CCMP
        group=CCMP
```

3. Connect WiFi access point and get IP-address

```
# wpa_supplicant -iwlxd037451c9c81 -c/etc/wpa_supplicant/wpa_supplicant.conf
# dhclient wlxd037451c9c81
```

The WiFi modules work well are Buffalo WLI-UC-GNM, PLANEX GW-USValue-EZ, TP-Link TL-WN725N, and Elecom WDC-150SU2MBK.

### Beforer running applictions

Then execute `init.sh`.
Executing this script is necessary every time before running ad-refkit applications.

``` sh
$ sh init.sh
```

### ad-sample

``` sh
$ cd <ROOT OF THIS REPOSITORY>/zybo/ROOT_FS/app/ad-sample
$ export AD_SAMPLE_ROOT=$(pwd)
$ mkdir build && cd build
$ cmake ..
$ make
$ ./ad-sample
```

![ad-sample](./ad-sample.png "ad-sample")

(sorry, this example picture is case not running on the course)

### make-calibration-param

Execute camera calibration by using OpenCV.
First of all, prepare image data by the following processes.

1. Print checkerboard (available on http://opencv.jp/sample/pics/chesspattern_7x10.pdf)
2. Take about 30 pictures of the checkerboard from various angles by using the calibration target camera.
    - Take pictures of whole of checkerboard.
    - Save pictures in a directory.
    - The extension of the files should be png.
    - The name of the files should be `img<#>.png`.
    - `<#>` should be series numbers from `0`.

After preparing picture files, start calibration.

``` sh
$ cd <ROOT OF THIS REPOSITORY>/zybo/ROOT_FS/app/make-calibration-param
$ mkdir build && cd build
$ cmake ..
$ make
$ ./make-calibration-param
```

### make-homography-param
Calculate the projection transformation matrix required to obtain a bird's eye view of the road surface in front of car.\
First of all, prepare image data by the follow steps.

1. Prepare a square of paper or a thin board
2. Place the prepared paper or a thin board on the floor in front of the front of the vehicle.
3. Take a picture of the paper or the board.

After preparing image data, run the follow program.

``` sh
$ python3 make-homography-param.py
```

Click on the corners of the square and specify the magnification and offset to output the projection transformation matrix.

### motor-test
This program checks the behavior of motors.

``` sh
$ cd <ROOT OF THIS REPOSITORY>/zybo/ROOT_FS/app/motor-test
$ mkdir build && cd build
$ cmake ..
$ make
$ ./motor-test
```

### pcam-test
This program checks the behavior of Pcam5C.

``` sh
$ cd <ROOT OF THIS REPOSITORY>/zybo/ROOT_FS/app/pcam-test
$ mkdir build && cd build
$ cmake ..
$ make
$ ./pcam-test
```

### webcam-test
This program checks the behavior of Web camera working.

``` sh
$ cd <ROOT OF THIS REPOSITORY>/zybo/ROOT_FS/app/webcam-test
$ mkdir build && cd build
$ cmake ..
$ make
$ ./webcam-test
```
