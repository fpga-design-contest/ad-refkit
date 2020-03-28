#!/bin/sh
if [ -n "$AD_REFKIT_SAMPLE_SCRIPT_PATH" ];
then
    cd $AD_REFKIT_SAMPLE_SCRIPT_PATH/../prj
    env SWT_GTK3=0 vivado_hls $AD_REFKIT_SAMPLE_SCRIPT_PATH/generate_hls_ip.tcl
    env SWT_GTK3=0 vivado -source $AD_REFKIT_SAMPLE_SCRIPT_PATH/create_prj.tcl
else
    echo "Prease set environment value like this."
    echo "$ cd <ROOT OF THIS REPOSITORY>/zybo/vivado/script"
    echo "$ export AD_REFKIT_SAMPLE_SCRIPT_PATH=\$(pwd)"
fi
