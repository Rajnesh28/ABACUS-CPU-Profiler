#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/io.h>

#define ABACUS_BASE_ADDR 0xf0030000
#define INSTRUCTION_PROFILE_UNIT_BASE_ADDR (ABACUS_BASE_ADDR + 0x0100)
#define CACHE_PROFILE_UNIT_BASE_ADDR (ABACUS_BASE_ADDR + 0x0200)

volatile unsigned int __iomem *INSTRUCTION_PROFILE_UNIT_ENABLE;
volatile unsigned int __iomem *CACHE_PROFILE_UNIT_ENABLE;

volatile unsigned int __iomem *LOAD_WORD_COUNTER_REG;
volatile unsigned int __iomem *STORE_WORD_COUNTER_REG;
volatile unsigned int __iomem *ADDITION_COUNTER_REG;
volatile unsigned int __iomem *SUBTRACTION_COUNTER_REG;
volatile unsigned int __iomem *LOGICAL_BITWISE_COUNTER_REG;
volatile unsigned int __iomem *SHIFT_BITWISE_COUNTER_REG;
volatile unsigned int __iomem *COMPARISON_COUNTER_REG;
volatile unsigned int __iomem *BRANCH_COUNTER_REG;
volatile unsigned int __iomem *JUMP_COUNTER_REG;
volatile unsigned int __iomem *SYSTEM_PRIVILEGE_COUNTER_REG;
volatile unsigned int __iomem *ATOMIC_COUNTER_REG;

volatile unsigned int __iomem *ICACHE_REQUEST_COUNTER_REG;
volatile unsigned int __iomem *ICACHE_HIT_COUNTER_REG;
volatile unsigned int __iomem *ICACHE_MISS_COUNTER_REG;
volatile unsigned int __iomem *ICACHE_LINE_FILL_LATENCY_COUNTER_REG;

volatile unsigned int __iomem *DCACHE_REQUEST_COUNTER_REG;
volatile unsigned int __iomem *DCACHE_HIT_COUNTER_REG;
volatile unsigned int __iomem *DCACHE_MISS_COUNTER_REG;
volatile unsigned int __iomem *DCACHE_LINE_FILL_LATENCY_COUNTER_REG;

static void instruction_profile(void) {
    printk(KERN_INFO "Instruction Profile Unit Registers:\n");
    printk(KERN_INFO "LOAD_WORD_COUNTER: %u\n", ioread32(LOAD_WORD_COUNTER_REG));
    printk(KERN_INFO "STORE_WORD_COUNTER: %u\n", ioread32(STORE_WORD_COUNTER_REG));
    printk(KERN_INFO "ADDITION_COUNTER: %u\n", ioread32(ADDITION_COUNTER_REG));
    printk(KERN_INFO "SUBTRACTION_COUNTER: %u\n", ioread32(SUBTRACTION_COUNTER_REG));
    printk(KERN_INFO "LOGICAL_BITWISE_COUNTER: %u\n", ioread32(LOGICAL_BITWISE_COUNTER_REG));
    printk(KERN_INFO "SHIFT_BITWISE_COUNTER: %u\n", ioread32(SHIFT_BITWISE_COUNTER_REG));
    printk(KERN_INFO "COMPARISON_COUNTER: %u\n", ioread32(COMPARISON_COUNTER_REG));
    printk(KERN_INFO "BRANCH_COUNTER: %u\n", ioread32(BRANCH_COUNTER_REG));
    printk(KERN_INFO "JUMP_COUNTER: %u\n", ioread32(JUMP_COUNTER_REG));
    printk(KERN_INFO "SYSTEM_PRIVILEGE_COUNTER: %u\n", ioread32(SYSTEM_PRIVILEGE_COUNTER_REG));
    printk(KERN_INFO "ATOMIC_COUNTER: %u\n", ioread32(ATOMIC_COUNTER_REG));
}

static int enable_instruction_profiling(void) {
    iowrite32(1, INSTRUCTION_PROFILE_UNIT_ENABLE);
    return 0;
}

static int disable_instruction_profiling(void) {
    iowrite32(0, INSTRUCTION_PROFILE_UNIT_ENABLE);
    return 0;
}

static void icache_profile(void) {
    printk(KERN_INFO "I-Cache Profile Unit Registers:\n");
    printk(KERN_INFO "ICACHE_REQUEST_COUNTER: %u\n", ioread32(ICACHE_REQUEST_COUNTER_REG));
    printk(KERN_INFO "ICACHE_HIT_COUNTER: %u\n", ioread32(ICACHE_HIT_COUNTER_REG));
    printk(KERN_INFO "ICACHE_MISS_COUNTER: %u\n", ioread32(ICACHE_MISS_COUNTER_REG));
    printk(KERN_INFO "ICACHE_LINE_FILL_LATENCY_COUNTER: %u\n", ioread32(ICACHE_LINE_FILL_LATENCY_COUNTER_REG));
}

static int enable_icache_profiling(void) {
    iowrite32(1, CACHE_PROFILE_UNIT_ENABLE);
    return 0;
}

static int disable_icache_profiling(void) {
    iowrite32(0, CACHE_PROFILE_UNIT_ENABLE);
    return 0;
}

static void dcache_profile(void) {
    printk(KERN_INFO "D-Cache Profile Unit Registers:\n");
    printk(KERN_INFO "DCACHE_REQUEST_COUNTER: %u\n", ioread32(DCACHE_REQUEST_COUNTER_REG));
    printk(KERN_INFO "DCACHE_HIT_COUNTER: %u\n", ioread32(DCACHE_HIT_COUNTER_REG));
    printk(KERN_INFO "DCACHE_MISS_COUNTER: %u\n", ioread32(DCACHE_MISS_COUNTER_REG));
    printk(KERN_INFO "DCACHE_LINE_FILL_LATENCY_COUNTER: %u\n", ioread32(DCACHE_LINE_FILL_LATENCY_COUNTER_REG));
}

static int enable_dcache_profiling(void) {
    iowrite32(1, CACHE_PROFILE_UNIT_ENABLE);
    return 0;
}

static int disable_dcache_profiling(void) {
    iowrite32(0, CACHE_PROFILE_UNIT_ENABLE);
    return 0;
}

static int __init abacus_profiler_init(void) {
    printk(KERN_INFO "Abacus Profiler Module Loaded.\n");

    // Map the physical memory addresses
    INSTRUCTION_PROFILE_UNIT_ENABLE = ioremap(ABACUS_BASE_ADDR + 0x04, sizeof(unsigned int));
    CACHE_PROFILE_UNIT_ENABLE = ioremap(ABACUS_BASE_ADDR + 0x08, sizeof(unsigned int));

    // Map all the registers for profiling
    LOAD_WORD_COUNTER_REG = ioremap(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x00, sizeof(unsigned int));
    STORE_WORD_COUNTER_REG = ioremap(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x04, sizeof(unsigned int));
    ADDITION_COUNTER_REG = ioremap(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x08, sizeof(unsigned int));
    SUBTRACTION_COUNTER_REG = ioremap(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x0C, sizeof(unsigned int));
    LOGICAL_BITWISE_COUNTER_REG = ioremap(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x10, sizeof(unsigned int));
    SHIFT_BITWISE_COUNTER_REG = ioremap(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x14, sizeof(unsigned int));
    COMPARISON_COUNTER_REG = ioremap(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x18, sizeof(unsigned int));
    BRANCH_COUNTER_REG = ioremap(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x1C, sizeof(unsigned int));
    JUMP_COUNTER_REG = ioremap(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x20, sizeof(unsigned int));
    SYSTEM_PRIVILEGE_COUNTER_REG = ioremap(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x24, sizeof(unsigned int));
    ATOMIC_COUNTER_REG = ioremap(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x28, sizeof(unsigned int));

    ICACHE_REQUEST_COUNTER_REG = ioremap(CACHE_PROFILE_UNIT_BASE_ADDR + 0x00, sizeof(unsigned int));
    ICACHE_HIT_COUNTER_REG = ioremap(CACHE_PROFILE_UNIT_BASE_ADDR + 0x04, sizeof(unsigned int));
    ICACHE_MISS_COUNTER_REG = ioremap(CACHE_PROFILE_UNIT_BASE_ADDR + 0x08, sizeof(unsigned int));
    ICACHE_LINE_FILL_LATENCY_COUNTER_REG = ioremap(CACHE_PROFILE_UNIT_BASE_ADDR + 0x0C, sizeof(unsigned int));

    DCACHE_REQUEST_COUNTER_REG = ioremap(CACHE_PROFILE_UNIT_BASE_ADDR + 0x10, sizeof(unsigned int));
    DCACHE_HIT_COUNTER_REG = ioremap(CACHE_PROFILE_UNIT_BASE_ADDR + 0x14, sizeof(unsigned int));
    DCACHE_MISS_COUNTER_REG = ioremap(CACHE_PROFILE_UNIT_BASE_ADDR + 0x18, sizeof(unsigned int));
    DCACHE_LINE_FILL_LATENCY_COUNTER_REG = ioremap(CACHE_PROFILE_UNIT_BASE_ADDR + 0x1C, sizeof(unsigned int));

    enable_instruction_profiling();
    enable_icache_profiling();
    enable_dcache_profiling();

    instruction_profile();
    icache_profile();
    dcache_profile();

    return 0;
}

static void __exit abacus_profiler_exit(void) {
    printk(KERN_INFO "Abacus Profiler Module Unloaded.\n");

    disable_instruction_profiling();
    disable_icache_profiling();
    disable_dcache_profiling();

    // Unmap the memory
    iounmap(INSTRUCTION_PROFILE_UNIT_ENABLE);
    iounmap(CACHE_PROFILE_UNIT_ENABLE);
    iounmap(LOAD_WORD_COUNTER_REG);
    iounmap(STORE_WORD_COUNTER_REG);
    iounmap(ADDITION_COUNTER_REG);
    iounmap(SUBTRACTION_COUNTER_REG);
    iounmap(LOGICAL_BITWISE_COUNTER_REG);
    iounmap(SHIFT_BITWISE_COUNTER_REG);
    iounmap(COMPARISON_COUNTER_REG);
    iounmap(BRANCH_COUNTER_REG);
    iounmap(JUMP_COUNTER_REG);
    iounmap(SYSTEM_PRIVILEGE_COUNTER_REG);
    iounmap(ATOMIC_COUNTER_REG);
    iounmap(ICACHE_REQUEST_COUNTER_REG);
    iounmap(ICACHE_HIT_COUNTER_REG);
    iounmap(ICACHE_MISS_COUNTER_REG);
    iounmap(ICACHE_LINE_FILL_LATENCY_COUNTER_REG);
    iounmap(DCACHE_REQUEST_COUNTER_REG);
    iounmap(DCACHE_HIT_COUNTER_REG);
    iounmap(DCACHE_MISS_COUNTER_REG);
    iounmap(DCACHE_LINE_FILL_LATENCY_COUNTER_REG);
}

module_init(abacus_profiler_init);
module_exit(abacus_profiler_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Your Name");
MODULE_DESCRIPTION("Abacus Profiler Kernel Module");
