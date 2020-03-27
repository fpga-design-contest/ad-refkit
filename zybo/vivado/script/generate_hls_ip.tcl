open_project preimproc_prj
set_top preimproc
add_files $env(AD_REFKIT_SAMPLE_SCRIPT_PATH)/../src/hls/preimproc/preimproc.cpp
add_files $env(AD_REFKIT_SAMPLE_SCRIPT_PATH)/../src/hls/preimproc/HlsImProc.hpp
open_solution "solution1"
set_part {xc7z020clg400-1} -tool vivado
create_clock -period 6.67 -name default
csynth_design
export_design -rtl verilog -format ip_catalog
