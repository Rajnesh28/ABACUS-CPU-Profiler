// This is a loadable kernel module which is meant to be a character device driver
// for userspace software to use to gather data from ABACUS in kernelspace on its behalf


#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/fs.h>
#include <linux/uaccess.h>
#include <linux/io.h>

#define DEVICE_NAME "abacus"
#define ABACUS_BASE_ADDR 0xf0030000

#define INSTRUCTION_PROFILE_UNIT_BASE_ADDR (ABACUS_BASE_ADDR + 0x0100)
#define CACHE_PROFILE_UNIT_BASE_ADDR (ABACUS_BASE_ADDR + 0x0200)
#define STALL_UNIT_BASE_ADDR (ABACUS_BASE_ADDR + 0x0300)

static int major_number;

static void __iomem *abacus_base;

static int device_open(struct inode *inode, struct file *file) {
	abacus_base = ioremap(ABACUS_BASE_ADDR, 0x1000); //Map physical address space into virtual address space ( https://lwn.net/Articles/653585/ )	
	if (!abacus_base) {
		pr_err("Could not map abacus physical address region to the virtual address space\n");
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
    char output[512];  // Buffer for storing the response to the command
    int output_len;
    size_t copy_len;

    // It may seem like a waste stack space to declare variables for every register in ABACUS,
    // but compiler warning stating that C90 forbids the mixing of declarations and assignments
    // provokes me to declare them all at the top incase the driver doesn't work after being uploaded to the 
    // FPGA via serial (which takes time)
    unsigned int load_word_counter;
    unsigned int store_word_counter;
    unsigned int addition_counter;
    unsigned int subtraction_counter;
    unsigned int branch_counter;
    unsigned int jump_counter;
    unsigned int system_counter;
    unsigned int atomic_counter;

    unsigned int icache_request_counter;
    unsigned int icache_hit_counter;
    unsigned int icache_miss_counter;
    unsigned int icache_line_fill_latency_counter;

    unsigned int dcache_request_counter;
    unsigned int dcache_hit_counter;
    unsigned int dcache_miss_counter;
    unsigned int dcache_line_fill_latency_counter;

    unsigned int branch_misprediction_counter;
    unsigned int ras_misprediction_counter;
    unsigned int issue_no_instruction_stat_counter;
    unsigned int issue_no_id_stat_counter;
    unsigned int issue_flush_stat_counter;
    unsigned int issue_unit_busy_stat_counter;
    unsigned int issue_operands_not_ready_stat_counter;
    unsigned int issue_hold_stat_counter;
    unsigned int issue_multi_source_stat_counter;


    output_len = 0;

    copy_len = min(len, sizeof(command) - 1);

    if (copy_len > sizeof(command) - 1) {
        pr_err("Device_read: The size of the command is greater than the buffer that will hold it\n");
        return -EINVAL;
    }

    if (copy_from_user(command, buffer, copy_len)) {
        pr_err("Device_read: Could not copy the buffer from user space to kernel space\n");
        return -EFAULT;
    }

    command[copy_len] = '\0';

    if (strcmp(command, "get_ip_stats") == 0) {
        load_word_counter = ioread32(abacus_base + 0x100);
        store_word_counter = ioread32(abacus_base + 0x104);
        addition_counter = ioread32(abacus_base + 0x108);
        subtraction_counter = ioread32(abacus_base + 0x10C);
        branch_counter = ioread32(abacus_base + 0x110);
        jump_counter = ioread32(abacus_base + 0x114);
        system_counter = ioread32(abacus_base + 0x118);
        atomic_counter = ioread32(abacus_base + 0x11C);

        pr_info("Debug: Read the IP unit\n");

        output_len = snprintf(output, sizeof(output),
                        "Load Word: %u\n"
                        "Store Word: %u\n"
                        "Addition: %u\n"
                        "Subtraction: %u\n"
                        "Branches: %u\n"
                        "Jumps: %u\n"
                        "System Privilege: %u\n"
                        "Atomic: %u\n",
                        load_word_counter, store_word_counter, addition_counter, subtraction_counter,
                        branch_counter, jump_counter, system_counter, atomic_counter);
    } 
    
    else if (strcmp(command, "get_icp_stats") == 0) {

		icache_request_counter = ioread32(abacus_base + 0x200);
		icache_hit_counter = ioread32(abacus_base + 0x204);
		icache_miss_counter = ioread32(abacus_base + 0x208);
		icache_line_fill_latency_counter = ioread32(abacus_base + 0x20C);

        pr_info("Debug: Read the ICP unit\n");

        output_len = snprintf(output, sizeof(output), 
                        "ICache Requests: %u\n"
                        "ICache Hits: %u\n"
                        "ICache Misses: %u\n"
                        "ICache Line Fill Latency Count: %u\n",
                        icache_request_counter, icache_hit_counter, icache_miss_counter, icache_line_fill_latency_counter);
    } 
    
    else if (strcmp(command, "get_dcp_stats") == 0) {
		dcache_request_counter = ioread32(abacus_base + 0x210);
		dcache_hit_counter = ioread32(abacus_base + 0x214);
		dcache_miss_counter = ioread32(abacus_base + 0x218);
		dcache_line_fill_latency_counter = ioread32(abacus_base + 0x21C);

        pr_info("Debug: Read the DCP unit\n");

        output_len = snprintf(output, sizeof(output), 
                        "DCache Requests: %u\n"
                        "DCache Hits: %u\n"
                        "DCache Misses: %u\n"
                        "ICache Line Fill Latency Count: %u\n",
                        dcache_request_counter, dcache_hit_counter, dcache_miss_counter, dcache_line_fill_latency_counter);
    } 
    
    else if (strcmp(command, "get_su_stats") == 0) {
		branch_misprediction_counter = ioread32(abacus_base + 0x300);
		ras_misprediction_counter = ioread32(abacus_base + 0x304);
		issue_no_instruction_stat_counter = ioread32(abacus_base + 0x308);
		issue_no_id_stat_counter = ioread32(abacus_base + 0x30C);
		issue_flush_stat_counter = ioread32(abacus_base + 0x310);
		issue_unit_busy_stat_counter = ioread32(abacus_base + 0x314);
		issue_operands_not_ready_stat_counter = ioread32(abacus_base + 0x318);
		issue_hold_stat_counter = ioread32(abacus_base + 0x31C);
		issue_multi_source_stat_counter = ioread32(abacus_base + 0x320);

        pr_info("Debug: Read the SU unit\n");

        output_len = snprintf(output, sizeof(output), 
                        "Branch Mispredictions: %u\n"
                        "RAS Mispredictions: %u\n"
                        "Issue No Instruction: %u\n"
                        "Issue No ID: %u\n"
                        "Issue Flush: %u\n"
                        "Issue Unit Busy: %u\n"
                        "Issue Operands Busy: %u\n"
                        "Issue Hold: %u\n"
                        "Issue Multi Source: %u\n",
                        branch_misprediction_counter, ras_misprediction_counter, issue_no_instruction_stat_counter, issue_no_id_stat_counter,
                        issue_flush_stat_counter, issue_unit_busy_stat_counter, issue_operands_not_ready_stat_counter, issue_hold_stat_counter, issue_multi_source_stat_counter);
    } 
    
    else {
        return -EINVAL; // Return invalid if the command is not recognized
    }

    // Copy the output back to the user space buffer
    if (copy_to_user(buffer, output, output_len)) {
        pr_info("device_read: Could not copy buffer data to userspace\n");
        return -EFAULT;
    }

    return output_len;
}


static ssize_t device_write(struct file *file, const char __user *buffer, size_t len, loff_t *offset) {
    char command[16];
    if (len > sizeof(command)) {
        pr_info("device_write: The size of the input buffer was too larger\n");
        return -EINVAL;
    }
    
    if (copy_from_user(command, buffer, len)) {
        pr_info("device_write: Copy from userspace did not occur properly\n");
        return -EFAULT;
    }

    command[len] = '\0';
	
	/*https://docs.kernel.org/driver-api/device-io.html*/

    if (strcmp(command, "enable_ip") == 0) {
        iowrite32(0x1, abacus_base + 0x04);
        pr_info("Debug: Successful write to the IP enable register\n");
    } 
	
    else if (strcmp(command, "disable_ip") == 0) {
        pr_info("Debug: Successful write to the IP disable register\n");
        iowrite32(0x0, abacus_base + 0x04);
    } 

    else if (strcmp(command, "enable_cp") == 0) {
        pr_info("Debug: Successful write to the CP enable register\n");
        iowrite32(0x1, abacus_base + 0x08);
    } 
	
    else if (strcmp(command, "disable_cp") == 0) {
        pr_info("Debug: Successful write to the CP disable register\n");
        iowrite32(0x0, abacus_base + 0x08);
    } 
	
    else if (strcmp(command, "enable_su") == 0) {
        pr_info("Debug: Successful write to the SU enable register\n");
		iowrite32(0x1, abacus_base + 0x0c);
    } 
	
    else if (strcmp(command, "disable_su") == 0) {
        pr_info("Debug: Successful write to the SU disable register\n");
		iowrite32(0x0, abacus_base + 0x0c);
    } 
    
    else {
        return -EINVAL;
    }

    return len;
}

static struct file_operations fops = {
	.open = device_open,
	.write = device_write,
	.read = device_read,
	.release = device_release
};

static int __init abacus_init(void) {
	//register_chrdev(...) will return the dynamically assigned character device number (https://tldp.org/LDP/lkmpg/2.6/html/x569.html)
	int major_number = register_chrdev(0, DEVICE_NAME, &fops); // Putting 0 for the major number tells the kernel to dynamically set the major number to one that is free
	if (major_number < 0) {
		pr_err("Could not register character device for abacus with %d\n", major_number);
		return major_number;
	}

	pr_info("Profiler module loaded with device major number %d\n", major_number); // Print the major number so we can define /dev/abacus with mknod
	return 0;
}

static void __exit abacus_exit(void) {
	unregister_chrdev(major_number, DEVICE_NAME);
	pr_info("ABACUS unloaded\n");
}

module_init(abacus_init);
module_exit(abacus_exit);

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Rajnesh Joshi");
MODULE_DESCRIPTION("Kernel driver for ABACUS");
