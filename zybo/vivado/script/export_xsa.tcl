#open project
open_project /home/boma/migrate/ad-refkit/zybo/vivado/prj/ad_refkit/ad_refkit.xpr
update_compile_order -fileset sources_1

#write xsa files for vitis
set_property pfm_name {} [get_files -all {../prj/ad_refkit/ad_refkit.srcs/sources_1/bd/design_1/design_1.bd}]
write_hw_platform -fixed -force -file ../prj/ad_refkit/zybo_top.xsa

