TEST_SOURCES = ql-tty2tcp.c
TEST_OBJS = $(TEST:.c=.o)
TEST_TARGET = quectelis

CFLAGS = -O0 -Wall -pthread


RM = rm -f

all:
	$(CC) $(TEST_SOURCES) $(CFLAGS) -o $(TEST_TARGET)

clean:
	$(RM) $(TEST_OBJS) $(TEST)
