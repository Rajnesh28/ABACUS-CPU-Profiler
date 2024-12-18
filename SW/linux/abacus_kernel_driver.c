#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/uaccess.h>
#include <linux/io.h>

#define DEVICE_NAME "abacus"
#define ABACUS_BASE_ADDR 0xf0030000

#define INSTRUCTION_PROFILE_UNIT_BASE_ADDR (ABACUS_BASE_ADDR + 0x100)
#define CACHE_PROFILE_UNIT_BASE_ADDR (ABACUS_BASE_ADDR + 0x0200)
#define STALL_UNIT_BASE_ADDR (ABACUS_BASE_ADDR + 0x0300)

static void __iomem *abacus_base;

static int device_open(struct inode *inode, struct file *file) {
	abacus_base = ioremap(ABACUS_BASE, 0x1000) //Map physical address space into virtual address space ( https://lwn.net/Articles/653585/ )	
	if (!abacus_base) {
		pr_err("Could not map abacus physical address region to the virtual address space");
		return -ENOMEM;
	}
	return 0;
}

static int device_release(struct inode *inode, struct file *file) {
	iounmap(abacus_base);
	return 0;
}

static ssize_t device_read(struct file *file, char __user *buffer, size_t len, loff_t *offset) {
	char command[16];

	if (len > sizeof(command) - 1)
		return -EINVAL;

	if (copy_from_user(command, buffer, len)) // Copy the buffer from user space to the buffe
		return -EFAULT;

	command[len] = '\0';

	char output[1024];

	if (strcmp(command, "get_ip_stats") == 0) {
		unsigned int load_word_counter = ioread32(abacus_base + 0x100);
		unsigned int store_word_counter = ioread32(abacus_base + 0x104);
		unsigned int addition_counter = ioread32(abacus_base + 0x108);
		unsigned int subtraction_counter = ioread32(abacus_base + 0x10C);
		unsigned int logical_bitwise_counter = ioread32(abacus_base + 0x110);
		unsigned int shift_bitwise_counter = ioread32(abacus_base + 0x114);
		unsigned int comparison_counter = ioread32(abacus_base + 0x118);
		unsigned int branch_counter = ioread32(abacus_base + 0x11C);
		unsigned int jump_counter = ioread32(abacus_base + 0x120);
		unsigned int system_counter = ioread32(abacus_base + 0x124);
		unsigned int atomic_counter = ioread32(abacus_base + 0x128);

        snprintf(output, sizeof(output),
                 "Load Word: %u\nStore Word: %u\nAddition: %u\nSubtraction: %u\nLogical Bitwise: %u
				 Shift Bitwise: %u\nComparisons: %u\nBranches: %u\nJumps: %u\nSystem Privilege: %u\n
				 Atomic: %u\n",
                 load_word_counter, store_word_counter, addition_counter, subtraction_counter, logical_bitwise_counter,
				 shift_bitwise_counter, comparison_counter, branch_counter, jump_counter, system_counter, atomic_counter);
	} else if (strcmp(command, "get_icp_stats") == 0) {
		unsigned int icache_request_counter = ioread32(abacus_base + 0x200);
		unsigned int icache_hit_counter = ioread32(abacus_base + 0x204);
		unsigned int icache_miss_counter = ioread32(abacus_base + 0x208);
		unsigned int icache_line_fill_latency_counter = ioread32(abacus_base + 0x20C);

		snprintf(output, sizeof(output), 
		"ICache Requests: %u\nICache Hits: %u\nICache Misses: %u\nICache Line Fill Latency Count %u\n",
		icache_request_counter, icache_hit_counter, icache_miss_counter, icache_line_fill_latency_counter);

	} else if (strcmp(command, "get_dcp_stats") == 0) {
		unsigned int dcache_request_counter = ioread32(abacus_base + 0x210);
		unsigned int dcache_hit_counter = ioread32(abacus_base + 0x214);
		unsigned int dcache_miss_counter = ioread32(abacus_base + 0x218);
		unsigned int dcache_line_fill_latency_counter = ioread32(abacus_base + 0x21C);

		snprintf(output, sizeof(output), 
		"DCache Requests: %u\nDCache Hits: %u\nDCache Misses: %u\nICache Line Fill Latency Count %u\n",
		dcache_request_counter, dcache_hit_counter, dcache_miss_counter, dcache_line_fill_latency_counter);
	} else if (strcmp(command, "get_su_stats") == 0) {
		unsigned int branch_misprediction_counter = ioread32(abacus_base + 0x300);
		unsigned int ras_misprediction_counter = ioread32(abacus_base + 0x304);
		unsigned int issue_no_instruction_stat_counter = ioread32(abacus_base + 0x308);
		unsigned int issue_no_id_stat_counter = ioread32(abacus_base + 0x30C);
		unsigned int issue_flush_stat_counter = ioread32(abacus_base + 0x310);
		unsigned int issue_unit_busy_stat_counter = ioread32(abacus_base + 0x314);
		unsigned int issue_operands_not_ready_stat_counter = ioread32(abacus_base + 0x318);
		unsigned int issue_hold_stat_counter = ioread32(abacus_base + 0x31C);
		unsigned int issue_multi_source_stat_counter = ioread32(abacus_base + 0x320);

		snprintf(output, sizeof(output), 
		"Branch Mispredictions: %u\nRAS Mispredictions: %u\nIssue No Instruction: %u\nIssue No ID %u\n
		Issue Flush: %u\nIssue Unit Busy: %u\n Issue Operands Busy: %u\nIssue Hold: %u\nIssue Multi Source: %u\n",
		branch_misprediction_counter, ras_misprediction_counter, issue_no_instruction_stat_counter, issue_no_id_stat_counter,
		issue_flush_stat_counter, issue_unit_busy_stat_counter, issue_operands_not_ready_stat_counter, issue_hold_stat_counter, issue_multi_source_stat_counter);
	} else {
		return -EINVAL;
	}

	if (copy_to_user(buffer, output, strlen(output)))
		return -EFAULT;

	return strlen(output);
}

static ssize_t device_write(struct file *file, const char __user *buffer, size_t len, loff_t *offset) {
    char command[16];
    if (len > sizeof(command) - 1)
        return -EINVAL;
    
    if (copy_from_user(command, buffer, len))
        return -EFAULT;
    
    command[len] = '\0';

    if (strcmp(command, "enable_ip") == 0) {
        iowrite32(0x1, abacus_base + 0x04);
    } else if (strcmp(command, "disable_ip") == 0) {
        iowrite32(0x0, abacus_base + 0x04);
    } else if (strcmp(command, "enable_cp") == 0) {
        iowrite32(0x1, abacus_base + 0x08);
    } else if (strcmp(command, "disable_cp") == 0) {
        iowrite32(0x0, abacus_base + 0x08);
    } else if (strcmp(command, "enable_su") == 0) {
		iowrite(0x1, abacus_base + 0x0c);
	} else if (strcmp(command, "disable_su") == 0) {
		iowrite(0x0, abacus_base + 0x0c);
	} else {
        return -EINVAL;
    }

    return len;
}

static int __init abacus_init(void) {
	int ret = register_chrdev(28, DEVICE_NAME, &fops);
	if (ret < 0) {
		pr_err("Could not initialize drivers for ABACUS");
		return ret;
	}

	pr_info("Profiler module loaded with device major number %d\n", ret);
	return 0;
}

static void __exit profiler_unit(void) {
	unregister_chrdev(0, DEVICE_NAME);
	pr_info("Abacus unloaded");
}

static struct file_operations fops = {
	.open = device_open,
	.write = device_write,
	.read = device_read,
	.release = device_release
}

module_init(abacus_init);
module_exit(abacus_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Rajnesh Joshi");
MODULE_DESCRIPTION("Kernel driver for ABACUS");