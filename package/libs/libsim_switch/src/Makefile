CC=gcc
WFLAGS=-Wall
CFLAGS=
INCLUDES=-Iinclude -lubus

LIBNAME=libsim_switch.so

all: $(LIBNAME)

%.o: %.c
	$(CC) $(WFLAGS) -c -o $@ $(INCLUDES) $(CFLAGS) $<

LIBNL_OBJ=sim_sw.o

$(LIBNAME): $(LIBNL_OBJ)
	$(CC) -shared -o $@ $^
