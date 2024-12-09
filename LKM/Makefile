obj-m += abacus.o

KDIR := /localhome/rajneshj/USRA/linux-5.18
# BUILD_DIR := /localhome/rajneshj/USRA/ABACUS/LKM/build

all:
	make -C $(KDIR) M=$(PWD) CROSS_COMPILE=riscv32-unknown-linux-gnu- ARCH=riscv modules

clean:
	make -C $(KDIR) M=$(pwd) CROSS_COMPILE=riscv32-unknown-linux-gnu- ARCH=riscv clean
