CC ?= cc
CFLAGS ?= -O2 -Wall -Wextra -static

arp_responder: arp_responder.c
	$(CC) $(CFLAGS) -o $@ $<

.PHONY: clean
clean:
	rm -f arp_responder
