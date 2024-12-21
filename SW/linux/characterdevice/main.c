#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>

#define DEVICE "/dev/abacus"

void enable_ip(int fd) {
    char cmd[16] = "enable_ip";
    write(fd, cmd, strlen(cmd) + 1); //string literal has automatic null character at the end,
				     //but strlen returns the size of char[] not including the null character
}

void disable_ip(int fd) {
    char cmd[16] = "disable_ip";
    write(fd, cmd, strlen(cmd) + 1);
}

void enable_cp(int fd) {
    char cmd[16] = "enable_cp";
    write(fd, cmd, strlen(cmd) + 1);
}

void disable_cp(int fd) {
    char cmd[16] = "disable_cp";
    write(fd, cmd, strlen(cmd) + 1);
}

void enable_su(int fd) {
    char cmd[16] = "enable_su";
    write(fd, cmd, strlen(cmd) + 1);
}

void disable_su(int fd) {
    char cmd[16] = "disable_su";
    write(fd, cmd, strlen(cmd) + 1);
}

void get_ip_stats(int fd) {
    char buffer[512] = "get_ip_stats";
    read(fd, buffer, sizeof(buffer));
    printf("%s\n", buffer);
}

void get_icp_stats(int fd) {
    char buffer[512] = "get_icp_stats";
    read(fd, buffer, sizeof(buffer));
    printf("%s\n", buffer);
}

void get_dcp_stats(int fd) {
    char buffer[512] = "get_dcp_stats";
    read(fd, buffer, sizeof(buffer));
    printf("%s\n", buffer);
}

void get_su_stats(int fd) {
    char buffer[512] = "get_su_stats";
    read(fd, buffer, sizeof(buffer));
    printf("%s\n", buffer);
}

void help() {
	printf("Available commands:\n");
	printf("help               - Print help screen (this)\n");
	printf("exit               - Exit software\n");
    
	printf("enable_ip          - Enable instruction profiling\n");
	printf("disable_ip         - Disable instruction profiling\n");
	printf("get_ip_stats       - Show instruction profiling stats\n");

	printf("enable_cp          - Enable cache profiling\n");
	printf("disable_cp         - Disable cache profiling\n");
	printf("get_icp_stats      - Show instruction cache profiling stats\n");
	printf("get_dcp_stats      - Show data cache profiling stats\n");

	printf("enable_su	       - Enable the stall unit profiler\n");
	printf("disable_su	       - Disable the stall unit profiler\n");
	printf("get_su_stats	   - Show stall unit stats\n");
}

int main() {

    /*  In order for this not to return an error eventually, 
    we need to ensure that we have loaded the kernel module with
    `insmod abacus.ko`, and also create a character device that populations
    /dev/abacus with `mknod /dev/abacus c 28 0`   */
    int fd = open(DEVICE, O_RDWR);
    char input[128];

    if (fd < 0) {
        printf("There was an error with opening the device\n");
        return -1;
    }

    while (1) {
        printf("abacus-linux-demo> ");
        if (fgets(input, sizeof(input), stdin) != NULL) {
            input[strcspn(input, "\n")] = 0;

            if (strcmp(input, "exit") == 0) {
                break;
            } else if (strcmp(input, "help") == 0) {
                help();
            }

            /*Enable profiling units*/
            else if (strcmp(input, "enable_ip") == 0) {
                enable_ip(fd);
            }
             else if (strcmp(input, "disable_ip") == 0) {
                disable_ip(fd);
            }

             else if (strcmp(input, "enable_cp") == 0) {
                enable_cp(fd);
            }
             else if (strcmp(input, "disable_cp") == 0) {
                disable_cp(fd);
            }

             else if (strcmp(input, "enable_su") == 0) {
                enable_su(fd);
            }
             else if (strcmp(input, "disable_su") == 0) {
                disable_su(fd);
            }

            /*Collect profiling unit data*/
             else if (strcmp(input, "get_ip_stats") == 0) {
                get_ip_stats(fd);
            }
             else if (strcmp(input, "get_icp_stats") == 0) {
                get_icp_stats(fd);
            }
             else if (strcmp(input, "get_dcp_stats") == 0) {
                get_dcp_stats(fd);
            }
             else if (strcmp(input, "get_su_stats") == 0) {
                get_su_stats(fd);
            } 
            
            else {
                printf("Unknown command \n"); //No valid command passed to fgets from stdin
            }
        }
    }

    printf("Goodbye \n");
    return 0;
}
