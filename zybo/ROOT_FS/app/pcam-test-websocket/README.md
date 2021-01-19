# pcam-test-websocket

This example displays png image captured by Pcam5c on your Web browser.
It is assumed that host machine and ad-refkit are connected with WiFi.

## Install required libraries

```
$ sudo apt install python3-pip
$ sudo apt install python3-gevent
$ sudo apt install python3-websocket
$ sudo pip3 install websockets
```

## Prepare

```
$ mkdir build
$ cd build
$ cmake ..
$ make
$ cd ..
```

## Start server

```
$ cd python
$ sudo ../build/pcam-test-websocket &
$ sudo python3 server.py &
$ sudo python3 -m http.server 8080 &
```

## Access via Web browser

Open http://IP-address-of-ad-refkit:8080/ by your Web browser on your host PC.

