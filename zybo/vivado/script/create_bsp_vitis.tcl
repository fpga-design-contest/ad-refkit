setws ../prj/ad_refkit/ad_refkit.sdk
platform create -name {ad_refkit} -hw {../prj/ad_refkit/zybo_top.xsa} -proc {ps7_cortexa9_0} -os {standalone} -out {../prj/ad_refkit/ad_refkit.sdk};platform write
# platform read {../prj/ad_refkit/ad_refkit.sdk/ad_refkit/platform.spr}
platform active {ad_refkit}
domain active {standalone_domain}
platform generate
