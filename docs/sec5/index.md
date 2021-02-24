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

1. Generate `wpa_supplicant.conf` (only first time to connect the target SSID)

```
# wpa_passphrase <YOUR SSID> <YOUR PASSWORD> > /etc/wpa_supplicant/wpa_supplicant.conf
```

2. Add some parameters in `/etc/wpa_supplicant/wpa_supplicant.conf` (only first time to connect the target SSID)

```
        proto=RSN
        key_mgmt=WPA-PSK
        pairwise=CCMP
        group=CCMP
```

3. Connect WiFi access point and get IP-address

```
# wpa_supplicant -iwlxd037451c9c81 -c/etc/wpa_supplicant/wpa_supplicant.conf &
# dhclient wlxd037451c9c81
```

The WiFi modules work well are Buffalo WLI-UC-GNM, PLANEX GW-USValue-EZ, TP-Link TL-WN725N, and Elecom WDC-150SU2MBK.

### Before running applictions

Execute `init.sh`.
Executing this script is necessary every time before running ad-refkit applications.

``` sh
$ sh init.sh
```
For Experimantal Vivado 2020.1 support, please execute init20201.sh instead.


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
(You should see in this process in [ad-refkit calibration](https://docs.google.com/presentation/d/18L2UL7cB7N1HqGs9Y_z4J0kfmSX4V-YpADnjRLmr1OU/edit#slide=id.p) (sorry written in Japanese))

Execute camera calibration by using OpenCV.
First of all, make `take-pcam-image` as the following.

``` sh
$ cd <ROOT OF THIS REPOSITORY>/zybo/ROOT_FS/app/take-pcam-image
$ mkdir build && cd build
$ cmake ..
$ make
```

And then, prepare image data by the following processes.

1. Print checkerboard (available on http://opencv.jp/sample/pics/chesspattern_7x10.pdf)
2. Take about 30 pictures of the checkerboard from various angles by using the calibration target camera with built `take-pcam-image`.
    - Take pictures of whole of checkerboard.
    - Save pictures in a directory.
    - The extension of the files should be png (as the application default).
    - The name of the files should be `img<#>.png` (as the application default).
    - `<#>` should be series numbers from `0` (as the application default).

After preparing picture files, start calibration.

``` sh
$ cd <ROOT OF THIS REPOSITORY>/zybo/ROOT_FS/app/make-calibration-param
$ mkdir build && cd build
$ cmake ..
$ make
$ ./make-calibration-param
```

The `make-calibration-param` execution should be like the following.

```
$ cd app/take-pcam-image
$ mkdir build
$ cmake ..
$ make
$ ./make-calibration-param 
Please input a path where you saved checkerboard images : ../data/
Please input the number of image : 30
Please input the number of checker board column : 10
Please input the number of checker board row : 7
Please input squares size (mm) : 23
…
```

The program displays pictures, enter some key to progress the operation.

After executing the program, you can get `calib_param.xml` in the directory. You should copy the generated `calib_param.xml` into apropreate directries.

```
$ cp calib_param.xml ../../pcam-test/data/pcam_calibration_parameter.xml
$ cp calib_param.xml ../../ad-sample/data/HWController/pcam_calibration_parameter.xml
```

### make-homography-param
(You should see in this process in [ad-refkit calibration](https://docs.google.com/presentation/d/18L2UL7cB7N1HqGs9Y_z4J0kfmSX4V-YpADnjRLmr1OU/edit#slide=id.p) (sorry written in Japanese))

Calculate the projection transformation matrix required to obtain a bird's eye view
of the road surface in front of car.
First of all, prepare image data by the follow steps.

1. Prepare a square of paper or a thin board
2. Place the prepared paper or a thin board on the floor in front of the front of the vehicle.
3. Take a picture of the paper or the board by using `take-pcam-image`

After preparing image data, run the follow program.

``` sh
$ python3 make-homography-param.py
```

The program should be execucted as below.

```
$ cd app/make-homography-param
$ python3 make-homography-param.py 
Please input a corrected image path from Pcam5C that has not been transformed.
Note that an image should be included a square pattern on the ground.
>> img2-0.png
Click on the square vertices in the image in the order shown below:
1. Top Left
2. Bottom Left
3. Top Right
4. Bottom Right
(385, 379)
(280, 638)
(790, 376)
(883, 634)
Please choose menu shown below:
'c': Specify ratio and Y-axis offset
'q': Quit and Show the homography matrix
```

Click on the corners of the square and specify the magnification and offset to output the projection transformation matrix.

```
Homography Matrix:
[ 0.154904608011 , -0.075484258313 , 62.9015488835 
 -0.00132486853534 , 0.0190262314547 , 104.989571058 
 -4.64648773206e-07 , -0.000125816562256 , 0.276168644843 ]
```

Copy the output matrix into `app/ad-sample/data/HWController/param.yaml` and `app/pcam-test/src/main.cpp`

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
