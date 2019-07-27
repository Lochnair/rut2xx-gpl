#ifndef SOCKET_H
#define SOCKET_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <errno.h>
#include <sys/socket.h>
#include "fdstate.h"

int socket_read(struct fd_state *state);
int socket_write(struct fd_state *state);

#endif
