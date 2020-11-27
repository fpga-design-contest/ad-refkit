# Hardware Design
This flow generates a sample IP-block, bit-stream for ZYBO Z7-20, and BSP for the generated HW.

## Requirements
- Host PC, installed Ubuntu 18.04
- Vivado 2019.1
- [Digilent board files](https://github.com/Digilent/vivado-boards)
- A license for MIPI CSI controller from [MIPI CSI Controller Subsystems](https://www.xilinx.com/products/intellectual-property/ef-di-mipi-csi-rx.html) This license is already included in your Vivado license if you obtained your Webpack license from January 2020, the following step might be required if you have the older Webpack license:
  - Access to [Product Licensing](http://www.xilinx.com/getlicense)
  - Click "Search Now"
  - Type "MIPI CSI" in "Search:" text field
  - Select "LogiCORE, MIPI CSI-2 Rx Controller, Evaluation License" and Click "Add" button
  - Find "LogiCORE, MIPI CSI-2 Rx Controller, Evaluation License", click checkbox of that, and click "Generate Node-Locked License"
  - Fill required license and you can get an evaluation license of MIPI CSI controller.

## Building Flow
Run the following script to generate hardware design. Make sure Vivado is in your path by sourcing the `settings64.sh` in Vivado's directory. 

``` sh
$ cd <ROOT OF THIS REPOSITORY>/zybo/vivado/script
$ export AD_REFKIT_SAMPLE_SCRIPT_PATH=$(pwd)
$ sh setup_bd.sh
```

The script starts Vivado HLS and Vivado to generate IP-block and bit-file. The working directory is `$AD_REFKIT_SAMPLE_SCRIPT_PATH/../prj` .
After running Vivado, the script generates `fpga.bin` in `<ROOT OF THIS REPOSITORY>/ROOT_FS/firmware`, which is a configuration file for dynamic reconfiguration of ZYBO Z7-20. Please follow the board manual on how to program the FPGA using the generated bit file.
The script also generates BSP for software development in `<ROOT OF THIS REPOSITORY>/zybo/ROOT_FS/zynq_bsp/`.

## Experimental Building Flow with Vivado 2020.1
Starting from Vivado 2020.1, the Xilinx XSDK is replaced with a new development platform called Vitis. The Vitis API is different compared to the old XSDK. Also, the MIPI CSI IP which is used in this project is updated. Therefore, we provide a different build script for Vivado 2020.1 platform. Once the project is initiated for Vivado 2020.1, it will not be able to be opened in older Vivado version.
The bit stream format of 2020.1 version also changes as the fpga-bit2bin.py script can no longer convert the bitstream into a proper bin file. The included bootgen from vivado does the trick. However, this change also requires a lot of other changes on the subsequent software build process as the new bin format cannot be recognized by the fpga_manager built into old Xilinx kernel. Newer format requires newer kernel from Xilinx repository and upgrading Linux kernel requires adjustment on the drivers and a lot of other things.
This build flow is experimantal and seems to be sensitive to the gcc version installed in the host PC among other things. Please run the following script if you would like to try.

``` sh
$ cd <ROOT OF THIS REPOSITORY>/zybo/vivado/script
$ export AD_REFKIT_SAMPLE_SCRIPT_PATH=$(pwd)
$ sh setup_bd_20201.sh
```
