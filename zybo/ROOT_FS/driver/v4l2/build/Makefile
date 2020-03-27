HOST_ARCH      ?= $(shell uname -m | sed -e s/arm.*/arm/ -e s/aarch64.*/arm64/)
ARCH           ?= arm
KERNEL_SRC_DIR ?= /lib/modules/$(shell uname -r)/build

SRC_PATH       ?= ../src
INCLUDE_PATH   ?= ../include
XLNX_SDK_DIR   ?= ../../../zynq_bsp/ps7_cortexa9_0
XLNX_HDR_DIR   ?= $(XLNX_SDK_DIR)/include
XLNX_VDMA_DIR  ?= $(XLNX_SDK_DIR)/libsrc/axivdma_v6_6/src
XLNX_MIPI_DIR  ?= $(XLNX_SDK_DIR)/libsrc/csi_v1_2/src

CFILES = $(SRC_PATH)/main.c\
         $(SRC_PATH)/ioctl.c\
         $(SRC_PATH)/vdma.c\
         $(SRC_PATH)/mipicsi.c\
         $(SRC_PATH)/dummy.c\
         $(XLNX_VDMA_DIR)/xaxivdma.c\
         $(XLNX_VDMA_DIR)/xaxivdma_channel.c\
         $(XLNX_VDMA_DIR)/xaxivdma_sinit.c\
         $(XLNX_VDMA_DIR)/xaxivdma_g.c\
         $(XLNX_VDMA_DIR)/xaxivdma_intr.c\
         $(XLNX_MIPI_DIR)/xcsi.c\
         $(XLNX_MIPI_DIR)/xcsi_sinit.c\
         $(XLNX_MIPI_DIR)/xcsi_intr.c\
         $(XLNX_MIPI_DIR)/xcsi_g.c

ifeq ($(ARCH), arm)
 ifneq ($(HOST_ARCH), arm)
   CROSS_COMPILE  ?= arm-linux-gnueabihf-
 endif
endif
ifeq ($(ARCH), arm64)
 ifneq ($(HOST_ARCH), arm64)
   CROSS_COMPILE  ?= aarch64-linux-gnu-
 endif
endif

obj-m     += v4l2.o
v4l2-objs := $(CFILES:.c=.o)
ccflags-y += -I$(PWD)/$(INCLUDE_PATH) -I$(PWD)/$(XLNX_VDMA_DIR) -I$(PWD)/$(XLNX_MIPI_DIR) -I$(PWD)/$(XLNX_HDR_DIR)

all:
	make -C $(KERNEL_SRC_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) M=$(PWD) modules

clean:
	make -C $(KERNEL_SRC_DIR) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) M=$(PWD) clean
	rm $(XLNX_VDMA_DIR)/*.o
	rm $(XLNX_MIPI_DIR)/*.o
