#include <stdio.h>
#include <stdlib.h>
#include <libtlt_uci/libtlt_uci.h>
#include <libsms_utils/smsutils.h>
#include <dirent.h>
#include <libgsm/sms.h>
#include <libeventslog/libevents.h>

/* includai socketui */
#include <sys/socket.h>
#include <sys/un.h>

#define UNIX_SOCK_PATH "/tmp/gsmd.sock"

char *appname = "ioman";
unsigned char nolog = 0;

int start_execute();
int execute_rules(struct uci_section *s);
int swich(char *action, char *section_name);
void rebootDevice(char *section_name);
int manageOutput(char *section_name);
void changeSIM();
int manageProfileChange(char *section_name);
int sendEmail(char *section_name);
char *parse_msg(char *text, char *min, char *max);
int manageSMS(char *section_name);
void sendSMS(char *phone_number, char *text,  char *min, char *max);
void new_event_log(char *text);
int ioman_start(char *m_input, char *m_value);
char *get_recipients(char *path);


#define GPIO_MAN_SCRIPT "/sbin/gpio.sh"
#define SIM_SWITCH_SCRIPT "/usr/sbin/sim_switch"
#define BUFFER_SIZE_MY 1024
