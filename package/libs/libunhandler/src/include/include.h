/*****************************************
 * 	Bendrai visuose failuose naudojami 
 * 	libs
 *****************************************/

#ifndef INCLUDE_H
#define INCLUDE_H

#include <time.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <stdlib.h>
#include <syslog.h>
#include <sys/types.h>
#include <signal.h>
#include <sys/socket.h>
#include <libgps/gps.h>
#include <libgsm/sms.h>
#include <libgsm/modem.h>
#include <libtlt_uci/libtlt_uci.h>
#include <libeventslog/libevents.h>
#include <sys/ioctl.h>
#include <netinet/in.h>
#include <net/if.h>

#define UNSOLICITED_DATA "/tmp/unsolicited_data"
#define UNSOLICITED_LOCK "/var/run/unsolicited_data_lock"
#define UNSOLICITED_DEBUG "/tmp/unsolicited_log"

#define UNIX_SOCK_PATH "/tmp/gsmd.sock"
#define OPERATOR_PATH "/tmp/operator"
//#define UNIX_SOCK_PATH "/tmp/unhandler.sock"

/*****************************************
 * 	define struct
 *****************************************/
static struct option long_options[] = {
	{ "read",			required_argument,	0,	'r' },
	{ "check",		no_argument,		0,	'c' },
	{ "startup",		no_argument,		0,	's' },
	{ "help",		no_argument,		0,	'h' },
	{ 0, 0, 0, 0 }
	};


#endif
