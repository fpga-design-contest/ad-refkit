# Hardware Design
This flow generates a sample IP-block, bit-stream for ZYBO Z7-20, and BSP for the generated HW.

## Requirements
- Host PC, with Ubuntu 18.04
- Vivado 2019.1
- [Digilent board files](https://github.com/Digilent/vivado-boards)
- A license for MIPI CSI controller from [MIPI CSI Controller Subsystems](https://www.xilinx.com/products/intellectual-property/ef-di-mipi-csi-rx.html) This license is already included in your Vivado license if you obtained your Webpack license from January 2020, the following step might be required if you have the older Webpack license:
  - Access to [Product Licensing](http://www.xilinx.com/getlicense)
  - Click "Search Now"
  - Type "MIPI CSI" in "Search:" text field
  - Select "LogiCORE, MIPI CSI-2 Rx Controller, Evaluation License" and Click "Add" button
  - Find "LogiCORE, MIPI CSI-2 Rx Controller, Evaluation License", click checkbox of that, and click "Generate Node-Locked License"
  - Fill required license and you can get an evaluation license of MIPI CSI controller.

## Building flow
Run the following script to generate hardware design. Make sure Vivado is in your path by sourcing the `settings64.sh` in Vivado's directory. 

``` sh
$ cd <ROOT OF THIS REPOSITORY>/zybo/vivado/script
$ export AD_REFKIT_SAMPLE_SCRIPT_PATH=$(pwd)
$ sh setup_bd.sh
```

Thi script starts Vivado HLS and Vivado to generate IP-block and bit-file. The working directory is `$AD_REFKIT_SAMPLE_SCRIPT_PATH/../prj` .
After running Vivado, the script generates `fpga.bin` in `<ROOT OF THIS REPOSITORY>/ROOT_FS/firmware`, which is a configuration file for dynamic reconfiguration of ZYBO Z7-20. Please follow the board manual on how to program the FPGA using the generated bit file.
The script also generates BSP for software development in `<ROOT OF THIS REPOSITORY>/zybo/ROOT_FS/zynq_bsp/`.

