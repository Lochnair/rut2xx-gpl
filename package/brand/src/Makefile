SOURCES = brand.c
OBJS = $(SOURCES:.c=.o)
TARGET = brand

CFLAGS = -Wall -lm -lbrand

RM = rm -f

all:
	$(CC) $(SOURCES) $(CFLAGS) -o $(TARGET)

clean:
	$(RM) $(OBJS) $(TARGET)