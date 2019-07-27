CC=gcc
WFLAGS=-Wall
CFLAGS=-O2 -lgsm
INCLUDES=-Iinclude

LIBNAME=libgps.so

all: $(LIBNAME)

%.o: %.c
	$(CC) $(WFLAGS) -c -o $@ $(INCLUDES) $(CFLAGS) $<

LIBNL_OBJ=gps.o socket.o fdstate.o

$(LIBNAME): $(LIBNL_OBJ)
	$(CC) -shared -o $@ $^
