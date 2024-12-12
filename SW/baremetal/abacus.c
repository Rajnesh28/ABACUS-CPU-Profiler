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

#define ABACUS_BASE_ADDR 0xf0030000
#define INSTRUCTION_PROFILE_UNIT_BASE_ADDR (ABACUS_BASE_ADDR + 0x0100)
#define CACHE_PROFILE_UNIT_BASE_ADDR (ABACUS_BASE_ADDR + 0x0200)

volatile unsigned int* INSTRUCTION_PROFILE_UNIT_ENABLE = (volatile unsigned int*)(ABACUS_BASE_ADDR + 0x04);
volatile unsigned int* CACHE_PROFILE_UNIT_ENABLE = (volatile unsigned int*)(ABACUS_BASE_ADDR + 0x08);

volatile unsigned int* LOAD_WORD_COUNTER_REG = (volatile unsigned int*)(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x00);
volatile unsigned int* STORE_WORD_COUNTER_REG = (volatile unsigned int*)(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x04);
volatile unsigned int* ADDITION_COUNTER_REG = (volatile unsigned int*)(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x08);
volatile unsigned int* SUBTRACTION_COUNTER_REG = (volatile unsigned int*)(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x0C);
volatile unsigned int* LOGICAL_BITWISE_COUNTER_REG = (volatile unsigned int*)(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x10);
volatile unsigned int* SHIFT_BITWISE_COUNTER_REG = (volatile unsigned int*)(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x14);
volatile unsigned int* COMPARISON_COUNTER_REG = (volatile unsigned int*)(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x18);
volatile unsigned int* BRANCH_COUNTER_REG = (volatile unsigned int*)(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x1C);
volatile unsigned int* JUMP_COUNTER_REG = (volatile unsigned int*)(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x20);
volatile unsigned int* SYSTEM_PRIVILEGE_COUNTER_REG = (volatile unsigned int*)(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x24);
volatile unsigned int* ATOMIC_COUNTER_REG = (volatile unsigned int*)(INSTRUCTION_PROFILE_UNIT_BASE_ADDR + 0x28);

volatile unsigned int* ICACHE_REQUEST_COUNTER_REG = (volatile unsigned int*)(CACHE_PROFILE_UNIT_BASE_ADDR + 0x00);
volatile unsigned int* ICACHE_HIT_COUNTER_REG = (volatile unsigned int*)(CACHE_PROFILE_UNIT_BASE_ADDR + 0x04);
volatile unsigned int* ICACHE_MISS_COUNTER_REG = (volatile unsigned int*)(CACHE_PROFILE_UNIT_BASE_ADDR + 0x08);
volatile unsigned int* ICACHE_LINE_FILL_LATENCY_COUNTER_REG = (volatile unsigned int*)(CACHE_PROFILE_UNIT_BASE_ADDR + 0x0C);

volatile unsigned int* DCACHE_REQUEST_COUNTER_REG = (volatile unsigned int*)(CACHE_PROFILE_UNIT_BASE_ADDR + 0x10);
volatile unsigned int* DCACHE_HIT_COUNTER_REG = (volatile unsigned int*)(CACHE_PROFILE_UNIT_BASE_ADDR + 0x14);
volatile unsigned int* DCACHE_MISS_COUNTER_REG = (volatile unsigned int*)(CACHE_PROFILE_UNIT_BASE_ADDR + 0x18);
volatile unsigned int* DCACHE_LINE_FILL_LATENCY_COUNTER_REG = (volatile unsigned int*)(CACHE_PROFILE_UNIT_BASE_ADDR + 0x1C);

void instruction_profile(void) {
    printf("The following are the number of issued instructions of a certain OPCODE type \n");
    printf("The number of load word: %u\n", *(LOAD_WORD_COUNTER_REG));
    printf("The number of store word: %u\n", *(STORE_WORD_COUNTER_REG));
    printf("The number of adds: %u\n", *(ADDITION_COUNTER_REG));
    printf("The number of subtractions: %u\n", *(SUBTRACTION_COUNTER_REG));
    printf("The number of logical bitwise operations: %u\n", *(LOGICAL_BITWISE_COUNTER_REG));
    printf("The number of shift bitwise operations: %u\n", *(SHIFT_BITWISE_COUNTER_REG));
    printf("The number of comparisons: %u\n", *(COMPARISON_COUNTER_REG));
    printf("The number of branches: %u\n", *(BRANCH_COUNTER_REG));
    printf("The number of jumps: %u\n", *(JUMP_COUNTER_REG));
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
    printf("The number of icache requests: %u\n", *(ICACHE_REQUEST_COUNTER_REG));
    printf("The number of icache hits: %u\n", *(ICACHE_HIT_COUNTER_REG));
    printf("The number of icache misses: %u\n", *(ICACHE_MISS_COUNTER_REG));
    printf("The average number of clock cycles to replace a line in the instruction cache with the current replacement policy is: %u\n", *(ICACHE_LINE_FILL_LATENCY_COUNTER_REG) / *(ICACHE_REQUEST_COUNTER_REG));
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
    printf("The number of dcache requests: %u\n", *(DCACHE_REQUEST_COUNTER_REG));
    printf("The number of dcache hits: %u\n", *(DCACHE_HIT_COUNTER_REG));
    printf("The number of dcache misses: %u\n", *(DCACHE_MISS_COUNTER_REG));
    printf("The average number of clock cycles to replace a line in the data cache with the current replacement policy is: %u\n", *(DCACHE_LINE_FILL_LATENCY_COUNTER_REG) / *(DCACHE_REQUEST_COUNTER_REG));
}

int enable_dcache_profiling(void) {
    *(CACHE_PROFILE_UNIT_ENABLE) = (unsigned int) 0x1;
    return (*(CACHE_PROFILE_UNIT_ENABLE) == 0x1);
}

int disable_dcache_profiling(void) {
    *(CACHE_PROFILE_UNIT_ENABLE) = (unsigned int) 0x0;
    return (*(CACHE_PROFILE_UNIT_ENABLE) == 0x0);
}
