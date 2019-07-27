CC=gcc
WFLAGS=-Wall
CFLAGS=-O2
INCLUDES=-Iinclude

LIBNAME=libunhandler.so

all: $(LIBNAME)

%.o: %.c
	$(CC) $(WFLAGS) -c -o $@ $(INCLUDES) $(CFLAGS) $<

LIBNL_OBJ=unhandler.o getpid.o lock.o

$(LIBNAME): $(LIBNL_OBJ)
	$(CC) -shared -o $@ $^
