#!/bin/sh
if [ -n "$AD_REFKIT_SAMPLE_SCRIPT_PATH" ];
then
    cd $AD_REFKIT_SAMPLE_SCRIPT_PATH/../prj
    rm -f vivado.jou
    rm -f vivado.log
    rm -f vivado_hls.log
    rm -rf ad_refkit
    rm -rf preimproc_prj
    env SWT_GTK3=0 vivado_hls $AD_REFKIT_SAMPLE_SCRIPT_PATH/generate_hls_ip.tcl
    patch $AD_REFKIT_SAMPLE_SCRIPT_PATH/create_prj.tcl $AD_REFKIT_SAMPLE_SCRIPT_PATH/update20201.patch
    env SWT_GTK3=0 vivado -mode batch -source $AD_REFKIT_SAMPLE_SCRIPT_PATH/create_prj.tcl
    env SWT_GTK3=0 vivado -mode batch -source $AD_REFKIT_SAMPLE_SCRIPT_PATH/export_xsa.tcl
    cd $AD_REFKIT_SAMPLE_SCRIPT_PATH
    chmod u+x fpga-bit2bin.py
    sh create_bitstream_bin.sh
    xsct $AD_REFKIT_SAMPLE_SCRIPT_PATH/create_bsp_vitis.tcl
    cp -R $AD_REFKIT_SAMPLE_SCRIPT_PATH/../prj/ad_refkit/ad_refkit.sdk/ad_refkit/ps7_cortexa9_0/standalone_domain/bsp/ps7_cortexa9_0 \
          $AD_REFKIT_SAMPLE_SCRIPT_PATH/../../ROOT_FS/zynq_bsp/
else
    echo "Please set environment value like this."
    echo "$ cd <ROOT OF THIS REPOSITORY>/zybo/vivado/script"
    echo "$ export AD_REFKIT_SAMPLE_SCRIPT_PATH=\$(pwd)"
fi
