#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>
#include <uci.h>

#define REMOVE 0
#define ADD 1
#define CHECK 2

#define BADKEY -1
#define GPS					1
#define RS485				2
#define CLI					3
#define DROPBEAR			4
#define RS232				5
#define MULTIWAN			6
#define PING_REBOOT			7
#define SAMBA				8
#define SIM_SWITCH			9
#define PRIVOXY				10
#define EVENTSLOG_REPORT	11
#define STRONGSWAN			12
#define SNMPD				13
#define REREGISTER			14
#define PPTPD				15
#define OUTPUT_CONTROL		16
#define SMPP_INIT			17
#define LOGTRIGGER			18
#define SIM_IDLE_PROTECTION	19
#define VRRPD				20
#define VRRP_CHECK			21
#define SIMPIN				22
#define RADIUS				23
#define OPENVPN_VPN			24
#define STUNNEL				25
#define MDCOLLECTD			26
#define SMSCOLLECT			27
#define HOSTBLOCK			28
#define LIMIT_GUARD			29
#define FTP_UPLOAD			30
#define EASYCWMP			31
#define GRE_TUNNEL			32
#define PERIODIC_REBOOT		33
#define SMS_GATEWAY			34
#define DHCP_RELAY			35
#define MOSQUITTO			36
#define MINIUPNP			37
#define MODBUSD				38
#define RMS_CONNECT			39
#define RELAYD				40

typedef struct { char *key; int val; } t_symstruct;

int checksv(int argc, char *argv[]);

int add_remove_symlink(char *init_d_name, int action);
