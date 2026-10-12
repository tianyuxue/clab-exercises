.PHONY: all clean

all: bgp-speaker

bgp-speaker: src/main.c src/bgp.h
	$(CC) -O2 -Wall -Wextra -static -o bgp-speaker src/main.c

clean:
	rm -f bgp-speaker
