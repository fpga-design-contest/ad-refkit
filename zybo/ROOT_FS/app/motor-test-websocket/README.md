# motor-test-websocket

This example controls motors via Web browser.
It is assumed that host machine and ad-refkit are connected with WiFi.

## Install required libraries

```
$ sudo apt install python3-pip
$ sudo apt install python3-gevent
$ sudo apt install python3-websocket
$ sudo pip3 install websocket-server
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
$ sudo python3 -m http.server 8080 &
$ sudo python3 server.py
```

## Access via Web browser

Open http://IP-address-of-ad-refkit:8080/websocket_client.html by Web browser on your host PC.

![motor-test-websocket-screenshot](./docs/motor-test-websocket-screenshot.png "motor-test-websocket-screenshot")
