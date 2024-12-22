# The kernel source directory
KERNELDIR ?= /localhome/rajneshj/USRA/buildroot/output/build/lkm_linux-5.18

ARCH := riscv
CROSS_COMPILE := /localhome/rajneshj/USRA/buildroot/output/host/bin/riscv32-buildroot-linux-gnu-
CC := $(CROSS_COMPILE)gcc

obj-m := kernelspace_lkm.o

CFLAGS_MODULE := -fno-asynchronous-unwind-tables -fno-unwind-tables

CFLAGS_MAIN := -Wall -Wextra

all: kernel_module main

kernel_module:
	$(MAKE) -C $(KERNELDIR) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) CC=$(CC) CFLAGS_MODULE="$(CFLAGS_MODULE)" modules

main: main.c
	$(CC) $(CFLAGS_MAIN) -o main main.c

clean: clean_kernel_module clean_main

clean_kernel_module:
	$(MAKE) -C $(KERNELDIR) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) CC=$(CC) clean

clean_main:
	rm -f main
