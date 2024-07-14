CC = gcc
CFLAGS = -fPIC -I$(ERL_INCLUDE_PATH) -shared

build:
	$(CC) $(CFLAGS) -o ./native/tuntap.so ./native/tuntap.c
