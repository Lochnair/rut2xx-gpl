#ifndef GPS_H
#define GPS_H
#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <stdlib.h>
#include <syslog.h>
#include <sys/stat.h>
#include <string.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <sys/time.h>
//#include "serial.h"
//#include "gpsd.inc.h"
#include <inttypes.h>
#include <math.h>
#include <semaphore.h>
#include <assert.h>
#include <uci.h>
#include <signal.h>
// Application requirements.
#include <sys/types.h>
#include <sys/stat.h>
#include <stdio.h> // Standard input/output definitions
#include <stdlib.h>
#include <fcntl.h> // File control definitions.
#include <errno.h> // Error number definitions
#include <unistd.h> // UNIX standard function definitions
#include <string.h> // String function definitions
#include <getopt.h> // Long options list
#include <sys/wait.h>

// Socket requirements.
#include <sys/socket.h>
#include <sys/un.h>

// Serial port requirements.
#include <termios.h>
#include <sys/time.h>

#include <libgsm/modem.h>
//#define 	SCNu16   "u"


#ifndef BUFFER_SIZE
#define BUFFER_SIZE 128
#endif

#ifndef GPS_UNIX_SOCK_PATH
#define GPS_UNIX_SOCK_PATH "/tmp/gpsd.sock"
#endif

#ifndef ARRAY_SIZE
#define ARRAY_SIZE(x) (sizeof(x) / sizeof((x)[0]))
#endif


typedef enum {
	LONGITUDE,
	LATITUDE,
	SPEED,
	FIX_TIME,
	DATETIME,
	ALTITUDE,
	SATELLITES,
	COURSE,
	STATUSAS,
	ACCURACY
} request_buff;

void change_input_status(char input[50]);
int send_to_gpsd(char *buffer);

#endif
