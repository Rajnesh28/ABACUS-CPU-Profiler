# The kernel source directory
KERNELDIR ?= /localhome/rajneshj/USRA/buildroot/output/build/lkm_linux-5.18

# Buildroot toolchain settings
ARCH := riscv
CROSS_COMPILE := /localhome/rajneshj/USRA/buildroot/output/host/bin/riscv32-buildroot-linux-gnu-
CC := $(CROSS_COMPILE)gcc

# Module name (abacus.ko)
obj-m := abacus.o

# Add custom CFLAGS for module compilation
CFLAGS_MODULE := -fno-asynchronous-unwind-tables -fno-unwind-tables

# Default target to compile the module
all:
	$(MAKE) -C $(KERNELDIR) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) CC=$(CC) CFLAGS_MODULE="$(CFLAGS_MODULE)" modules

# Clean target to remove generated files
clean:
	$(MAKE) -C $(KERNELDIR) M=$(PWD) ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) CC=$(CC) clean

