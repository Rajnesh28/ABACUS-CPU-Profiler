#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>

#define DEVICE "/dev/abacus"

void enable_ip(void) {
    char cmd[256] = "enable_ip";
    write(DEVICE, cmd, sizeof(cmd));
}

void disable_ip(void) {
    char cmd[256] = "disable_ip";
    write(DEVICE, cmd, sizeof(cmd));
}

void enable_icp(void) {
    char cmd[256] = "enable_icp";
    write(DEVICE, cmd, sizeof(cmd));
}

void disable_icp(void) {
    char cmd[256] = "disable_icp";
    write(DEVICE, cmd, sizeof(cmd));
}

void enable_dcp(void) {
    char cmd[256] = "enable_dcp";
    write(DEVICE, cmd, sizeof(cmd));
}

void disable_dcp(void) {
    char cmd[256] = "disable_dcp";
    write(DEVICE, cmd, sizeof(cmd));
}

void enable_su(void) {
    char cmd[256] = "enable_su";
    write(DEVICE, cmd, sizeof(cmd));
}

void disable_su(void) {
    char cmd[256] = "disable_su";
    write(DEVICE, cmd, sizeof(cmd));
}

void get_ip_stats(void) {
    char buffer[256] = "get_ip_stats";
    read(DEVICE, buffer, sizeof(buffer));
    printf("%s", buffer);
}

void get_icp_stats(void) {
    char buffer[256] = "get_icp_stats";
    read(DEVICE, buffer, sizeof(buffer));
    printf("%s", buffer);
}

void get_dcp_stats(void) {
    char buffer[256] = "get_dcp_stats";
    read(DEVICE, buffer, sizeof(buffer));
    printf("%s", buffer);
}

void get_su_stats(void) {
    char buffer[256] = "get_su_stats";
    read(DEVICE, buffer, sizeof(buffer));
    printf("%s", buffer);
}

int main() {
    int fd = open(DEVICE, O_RDWR);

    int (fd < 0) {
        printf("There was an error with opening the device");
        return -1;
    }

    while (1) {
        printf("abacus-linux-demo> ");
        if (fgets(input, sizeof(input), stdin) != NULL) {
            input[strcspn(input, "\n")] = 0;

            if ((strcmp, "exit") == 0) {
                break;
            } 
            
            /*Enable profiling units*/
            else if ((strcmp(enable_ip) == 0)) {
                enable_ip(void);
            }
             else if ((strcmp(disable_ip) == 0)) {
                disable_ip(void);
            }
             else if ((strcmp(enable_icp) == 0)) {
                enable_icp(void);
            }
             else if ((strcmp(disable_icp) == 0)) {
                disable_icp(void);
            }
             else if ((strcmp(enable_dcp) == 0)) {
                enable_dcp(void);
            }
             else if ((strcmp(disable_dcp) == 0)) {
                disable_dcp(void);
            }
             else if ((strcmp(enable_su) == 0)) {
                enable_su(void);
            }
             else if ((strcmp(disable_su) == 0)) {
                disable_su(void);
            }

            /*Collect profiling unit data*/
             else if ((strcmp(get_ip_stats) == 0)) {
                get_ip_stats(void);
            }
             else if ((strcmp(get_icp_stats) == 0)) {
                get_icp_stats(void);
            }
             else if ((strcmp(get_dcp_stats) == 0)) {
                get_dcp_stats(void);
            }
             else if ((strcmp(get_su_stats) == 0)) {
                get_su_stats(void);
            } else {
                printf("Unknown command \n"); //No valid command passed to fgets from stdin
            }
        }
    }

    printf("Goodbye \n");
    return 0;
}
