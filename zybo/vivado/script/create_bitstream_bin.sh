#!/bin/sh
SCRIPT_DIR=$(cd $(dirname $0); pwd)

TARGET_FILE_NAME=fpga.bin

TARGET_DIR=$SCRIPT_DIR/../../ROOT_FS/firmware

BIT_FILE_DIR=$SCRIPT_DIR/../prj/ad_refkit/ad_refkit.runs/impl_1

BIT_FILE_NAME=$(ls $BIT_FILE_DIR | grep .*.bit$)

./fpga-bit2bin.py --flip $BIT_FILE_DIR/$BIT_FILE_NAME $TARGET_DIR/$TARGET_FILE_NAME

echo "[SUCCESS] create $TARGET_DIR/$TARGET_FILE_NAME"
