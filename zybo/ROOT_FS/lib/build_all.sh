#!/bin/sh
SCRIPT_DIR=$(cd $(dirname $0); pwd)

# zynqpl
cd $SCRIPT_DIR/zynqpl
mkdir -p build && cd build
cmake .. && make -j2
ln -sfn $SCRIPT_DIR/zynqpl/build/libzynqpl.so $SCRIPT_DIR/libzynqpl.so
ln -sfn $SCRIPT_DIR/zynqpl/include $SCRIPT_DIR/include/zynqpl

# imploc
cd $SCRIPT_DIR/improc
mkdir -p build && cd build
cmake .. && make -j2
ln -sfn $SCRIPT_DIR/improc/build/libimproc.so $SCRIPT_DIR/libimproc.so
ln -sfn $SCRIPT_DIR/improc/include $SCRIPT_DIR/include/improc
