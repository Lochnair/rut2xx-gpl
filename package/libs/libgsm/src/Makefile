CC=gcc
WFLAGS=-Wall
CFLAGS=-O2
INCLUDES=-Iinclude

LIBNAME=libgsm.so

all: $(LIBNAME)

%.o: %.c
	$(CC) $(WFLAGS) -c -o $@ $(INCLUDES) $(CFLAGS) $<

LIBNL_OBJ=sms.o pduconv.o modem.o uci_function.o

$(LIBNAME): $(LIBNL_OBJ)
	$(CC) -shared -leventslog -o $@ $^
