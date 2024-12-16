#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <irq.h>
#include <libbase/uart.h>
#include <libbase/console.h>
#include <generated/csr.h>

// Function Prototypes
static char *readstr(void);
static char *get_token(char **str);
static void prompt(void);
static void help(void);
static void reboot_cmd(void);
static void console_service(void);

extern void instruction_profile(void);
extern int enable_instruction_profiling(void);
extern int disable_instruction_profiling(void);
extern void icache_profile(void);
extern int enable_icache_profiling(void);
extern int disable_icache_profiling(void);
extern void dcache_profile(void);
extern int enable_dcache_profiling(void);
extern int disable_dcache_profiling(void);
extern int enable_stall_unit(void);
extern int disable_stall_unit(void);
extern void stall_unit_profile(void);

/*-----------------------------------------------------------------------*/
/* Basic String Input and Token Handling                                 */
/*-----------------------------------------------------------------------*/

static char *readstr(void) {
	char c[2];
	static char s[64];
	static int ptr = 0;

	if (readchar_nonblock()) {
		c[0] = getchar();
		c[1] = 0;
		switch (c[0]) {
			case 0x7f:
			case 0x08:
				if (ptr > 0) {
					ptr--;
					fputs("\x08 \x08", stdout);
				}
				break;
			case 0x07:
				break;
			case '\r':
			case '\n':
				s[ptr] = 0x00;
				fputs("\n", stdout);
				ptr = 0;
				return s;
			default:
				if (ptr >= (sizeof(s) - 1)) break;
				fputs(c, stdout);
				s[ptr] = c[0];
				ptr++;
				break;
		}
	}

	return NULL;
}

static char *get_token(char **str) {
	char *c, *d;

	c = (char *)strchr(*str, ' ');
	if (c == NULL) {
		d = *str;
		*str = *str + strlen(*str);
		return d;
	}
	*c = 0;
	d = *str;
	*str = c + 1;
	return d;
}

/*-----------------------------------------------------------------------*/
/* Prompt and Help                                                       */
/*-----------------------------------------------------------------------*/

static void prompt(void) {
	printf("\e[92;1mlitex-demo-app\e[0m> ");
}

static void help(void) {
	puts("Available commands:");
	puts("help               - Show this command");
	puts("reboot             - Reboot CPU");
	puts("enable_ip          - Enable instruction profiling");
	puts("disable_ip         - Disable instruction profiling");
	puts("get_ip_stats       - Show instruction profiling stats");
	puts("enable_icp         - Enable instruction cache profiling");
	puts("disable_icp        - Disable instruction cache profiling");
	puts("get_icp_stats      - Show instruction cache profiling stats");
	puts("enable_dcp         - Enable data cache profiling");
	puts("disable_dcp        - Disable data cache profiling");
	puts("get_dcp_stats      - Show data cache profiling stats");
	puts("enable_su			 - Enable the stall unit profiler");
	puts("disable_su		 - Disable the stall unit profiler");
	puts("get_su_stats		 - Show stall unit stats");
}

/*-----------------------------------------------------------------------*/
/* Commands                                                              */
/*-----------------------------------------------------------------------*/

static void reboot_cmd(void) {
	ctrl_reset_write(1);
}

static void instruction_profile_cmd(void) {
	instruction_profile();
}
static int enable_instruction_profiling_cmd(void) {
	enable_instruction_profiling();
}
static int disable_instruction_profiling_cmd(void) {
	disable_instruction_profiling();
}
static void icache_profile_cmd(void) {
	icache_profile();
}
static int enable_icache_profiling_cmd(void) {
	enable_icache_profiling();
}
static int disable_icache_profiling_cmd(void) {
	disable_icache_profiling();
}
static void dcache_profile_cmd(void) {
	dcache_profile();
}
static int enable_dcache_profiling_cmd(void) {
	enable_dcache_profiling();
}
static int disable_dcache_profiling_cmd(void) {
	disable_dcache_profiling();
}

static int enable_stall_unit_cmd(void) {
	enable_stall_unit();
}

static int disable_stall_unit_cmd(void) {
	disable_stall_unit();
}

static void stall_unit_profile_cmd(void) {
	stall_unit_profile();
}

/*-----------------------------------------------------------------------*/
/* Console Service                                                       */
/*-----------------------------------------------------------------------*/

static void console_service(void) {
	char *str;
	char *token;
	prompt();
	str = readstr();
	if (str == NULL) return;

	token = get_token(&str);

	if (strcmp(token, "help") == 0) {
		help();
	} else if (strcmp(token, "reboot") == 0) {
		reboot_cmd();
	} else if (strcmp(token, "enable_ip") == 0) {
		if (enable_instruction_profiling_cmd())
			printf("Instruction profiling enabled!\n");
		else
			printf("Error: Could not enable instruction profiling\n");
	} else if (strcmp(token, "disable_ip") == 0) {
		if (disable_instruction_profiling_cmd())
			printf("Instruction profiling disabled!\n");
		else
			printf("Error: Could not disable instruction profiling\n");
	} else if (strcmp(token, "get_ip_stats") == 0) {
		instruction_profile_cmd();
	} else if (strcmp(token, "enable_icp") == 0) {
		if (enable_icache_profiling_cmd())
			printf("Instruction cache profiling enabled!\n");
		else
			printf("Error: Could not enable instruction cache profiling\n");
	} else if (strcmp(token, "disable_icp") == 0) {
		if (disable_icache_profiling_cmd())
			printf("Instruction cache profiling disabled!\n");
		else
			printf("Error: Could not disable instruction cache profiling\n");
	} else if (strcmp(token, "get_icp_stats") == 0) {
		icache_profile_cmd();
	} else if (strcmp(token, "enable_dcp") == 0) {
		if (enable_dcache_profiling_cmd())
			printf("Data cache profiling enabled!\n");
		else
			printf("Error: Could not enable data cache profiling\n");
	} else if (strcmp(token, "disable_dcp") == 0) {
		if (disable_dcache_profiling_cmd())
			printf("Data cache profiling disabled!\n");
		else
			printf("Error: Could not disable data cache profiling\n");
	} else if (strcmp(token, "get_dcp_stats") == 0) {
		dcache_profile();
	} else if (strcmp(token, "enable_su") == 0) {
		if (enable_stall_unit_cmd())
			printf("Stall unit enabled\n");
		else
			printf("Error: Could not enable stall unit");
	} else if (strcmp(token, "disable_su") == 0) {
		if (disable_stall_unit_cmd())
			printf("Stall unit disabled\n");
		else
			printf("Error: Could not disable stall unit");
	} else if (strcmp(token, "get_su_stats") == 0) {
		stall_unit_profile_cmd();
	} else {
		printf("Unknown command: %s\n", token);
	}
}

int main(void) {
	irq_setmask(0);
	irq_setie(1); // Enable interrupts
	uart_init();

	puts("\nABACUS Bare Metal Program built on "__DATE__" "__TIME__"\n");
	help();
	prompt();

	while (1) {
		console_service();
	}

	return 0;
}
