#!/bin/bash

# MIT License
#
# Copyright (c) 2022 David Schall and EASE lab
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

MKFILE 		:= $(abspath $(lastword $(MAKEFILE_LIST)))
ROOT 		:= $(abspath $(dir $(MKFILE))/../)


## User specific inputs
RES 	?= $(ROOT)/bm-disk/tmp-j/
WORKING_DIR ?= wkdir3/
# WORKING_DIR ?= $(ROOT)/wkdir/


## Machine parameter
MEMORY 	:= 2G
CPUS    := 2
CPU 	?= host -enable-kvm


## Required artifacts
ARTIFACTS_DIR := $(ROOT)/image/artifacts/


KERNEL  := $(ARTIFACTS_DIR)/kernel
CLIENT 	:= $(ARTIFACTS_DIR)/http-client
# DISK	:= $(ARTIFACTS_DIR)/disk-image.qcow2
DISK	:= $(ROOT)/image/output-noble/ubuntu-noble.img


## Dependencies -------------------------------------------------
$(ARTIFACTS_DIR):
	mkdir -p $@
	# $(ROOT)/image/artifacts.py -o $@ --os-version=focal --arch=arm64
	

$(CLIENT): $(ARTIFACTS_DIR)
	cd $(ROOT)/client && \
	ARCH=arm64 make all
	cp $(ROOT)/client/http-client $@
	



##################################################################
## Build the working directory ----------------------------
#
WK_KERNEL 	:= $(WORKING_DIR)/kernel
WK_DISK 	:= $(WORKING_DIR)/disk.img
WK_CLIENT	:= $(WORKING_DIR)/test-client

build-wkdir: $(WORKING_DIR) $(ARTIFACTS_DIR) \
	$(WK_DISK) $(WK_KERNEL) $(WK_CLIENT)


$(WORKING_DIR):
	@echo "Create folder: $(WORKING_DIR)"
	mkdir -p $@

# $(WK_KERNEL): $(KERNEL)
# 	cp $< $@

$(WK_KERNEL): 
	wget -O $@ https://github.com/vhive-serverless/vSwarm-u/releases/download/v0.3.0/vmlinux-jammy-arm64


$(WK_CLIENT): $(CLIENT)
	cp $< $@


# Create the disk image from the base image
$(WK_DISK): $(DISK)
	qemu-img convert $< $@



## Run Emulator -------------------------------------------------


FLASH0 := $(WORKING_DIR)/flash0.img
FLASH1 := $(WORKING_DIR)/flash1.img

$(FLASH0):
	cp /usr/share/qemu-efi-aarch64/QEMU_EFI.fd $@
	truncate -s 64M $@

$(FLASH1):
	truncate -s 64M $@


run: $(FLASH0) $(FLASH1)
	sudo qemu-system-aarch64 \
		-nographic \
		-M virt \
		-machine gic-version=max \
		-cpu host -enable-kvm \
		-smp ${CPUS} -m ${MEMORY} \
		-device e1000,netdev=net0 \
    	-netdev type=user,id=net0,hostfwd=tcp:127.0.0.1:5555-:22  \
		-drive file=$(WK_DISK),format=raw \
		-drive file=$(FLASH0),format=raw,if=pflash -drive file=$(FLASH1),format=raw,if=pflash 
