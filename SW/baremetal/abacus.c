#include <stdio.h>

// Function Prototypes
void instruction_profile(void);
int enable_instruction_profiling(void);
int disable_instruction_profiling(void);
void icache_profile(void);
int enable_icache_profiling(void);
int disable_icache_profiling(void);
void dcache_profile(void);
int enable_dcache_profiling(void);
int disable_dcache_profiling(void);
static void console_service(void);

#define ABACUS_BASE_ADDR 0xf0030000
#define INSTRUCTION_PROFILE_UNIT_BASE_ADDR (ABACUS_BASE_ADDR + 0x0100)
#define CACHE_PROFILE_UNIT_BASE_ADDR (ABACUS_BASE_ADDR + 0x0200)

volatile unsigned int* INSTRUCTION_PROFILE_UNIT_ENABLE = (volatile unsigned int*)(ABACUS_BASE_ADDR + 0x04);
volatile unsigned int* CACHE_PROFILE_UNIT_ENABLE = (volatile unsigned int*)(ABACUS_BASE_ADDR + 0x08);

volatile unsigned int* LOAD_WORD_COUNTER_REG = (volatile unsigned int*)(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x00);
volatile unsigned int* STORE_WORD_COUNTER_REG = (volatile unsigned *)(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x04);
volatile unsigned int* ADD_COUNTER_REG = (volatile unsigned *)(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x08);
volatile unsigned int* MUL_COUNTER_REG = (volatile unsigned *)(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x0C);
volatile unsigned int* DIV_COUNTER_REG = (volatile unsigned *)(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x10);
volatile unsigned int* BITWISE_COUNTER_REG = (volatile unsigned *)(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x14);
volatile unsigned int* SHIFT_ROTATE_COUNTER_REG = (volatile unsigned *)(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x18);
volatile unsigned int* COMPARISON_COUNTER_REG = (volatile unsigned *)(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x1C);
volatile unsigned int* BRANCH_COUNTER_REG = (volatile unsigned *)(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x20);
volatile unsigned int* CONTROL_TRANSFER_COUNTER_REG = (volatile unsigned *)(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x24);
volatile unsigned int* SYSTEM_PRIVILEGE_COUNTER_REG = (volatile unsigned *)(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x28);
volatile unsigned int* ATOMIC_COUNTER_REG = (volatile unsigned *)(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x2C);
volatile unsigned int* FLOATING_POINT_COUNTER_REG = (volatile unsigned *)(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x30);

void instruction_profile(void) {
	printf("The load word instructions issued: %u\n", *(LOAD_WORD_COUNTER_REG));
	printf("The store word instructions issued: %u\n", *(STORE_WORD_COUNTER_REG));
	printf("The number of adds: %u\n", *(ADD_COUNTER_REG));
	printf("The number of bitwise operations: %u\n", *(BITWISE_COUNTER_REG));
	printf("The number of shift rotates: %u\n", *(SHIFT_ROTATE_COUNTER_REG));
	printf("The number of comparisons: %u\n", *(COMPARISON_COUNTER_REG));
	printf("The number of branches: %u\n", *(BRANCH_COUNTER_REG));
	printf("The number of control transfers: %u\n", *(CONTROL_TRANSFER_COUNTER_REG));
	printf("The number of system privilege instructions: %u\n", *(SYSTEM_PRIVILEGE_COUNTER_REG));
	printf("The number of atomic instructions: %u\n", *(ATOMIC_COUNTER_REG));
}

int enable_instruction_profiling(void) {
	*(INSTRUCTION_PROFILE_UNIT_ENABLE) = (unsigned int) 0x1;
	return (*(INSTRUCTION_PROFILE_UNIT_ENABLE) == 0x1);
}

int disable_instruction_profiling(void) {
	*(INSTRUCTION_PROFILE_UNIT_ENABLE) = (unsigned int) 0x0;
	return (*(INSTRUCTION_PROFILE_UNIT_ENABLE) == 0x0);
}

void icache_profile(void) {
	// Placeholder for displaying Instruction Cache profiling statistics
	printf("Instruction Cache profiling not implemented yet.\n");
}

int enable_icache_profiling(void) {
	*(CACHE_PROFILE_UNIT_ENABLE) = (unsigned int) 0x1;
	return (*(CACHE_PROFILE_UNIT_ENABLE) == 0x1);
}

int disable_icache_profiling(void) {
	*(CACHE_PROFILE_UNIT_ENABLE) = (unsigned int) 0x0;
	return (*(CACHE_PROFILE_UNIT_ENABLE) == 0x0);
}

void dcache_profile(void) {
	// Placeholder for displaying Data Cache profiling statistics
	printf("Data Cache profiling not implemented yet.\n");
}

int enable_dcache_profiling(void) {
	*(CACHE_PROFILE_UNIT_ENABLE) = (unsigned int) 0x1;
	return (*(CACHE_PROFILE_UNIT_ENABLE) == 0x1);
}

int disable_dcache_profiling(void) {
	*(CACHE_PROFILE_UNIT_ENABLE) = (unsigned int) 0x0;
	return (*(CACHE_PROFILE_UNIT_ENABLE) == 0x0);
}