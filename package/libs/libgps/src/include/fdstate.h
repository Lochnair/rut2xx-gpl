#ifndef FDSTATE_H
#define FDSTATE_H

#define MAX_LINE 16384

#include <stdio.h>
#include <stdlib.h>

struct fd_state {
	int fd;
	char buffer[MAX_LINE];
	size_t buffer_used;

	int writing;
	size_t n_written;
	size_t write_upto;
};

struct fd_state * alloc_fd_state(void);
void free_fd_state(struct fd_state *state);

#endif
