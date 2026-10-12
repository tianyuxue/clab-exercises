#ifndef BGP_H
#define BGP_H

#include <stddef.h>
#include <stdint.h>

#define BGP_PORT 179

#define MSG_OPEN 1
#define MSG_UPDATE 2
#define MSG_NOTIFICATION 3
#define MSG_KEEPALIVE 4

/* Connect a TCP socket to host:port. Returns the fd, or -1 on error. */
int tcp_connect(const char *host, uint16_t port);

/* Write exactly len bytes, looping over short writes. Returns 0 or -1. */
int send_all(int fd, const uint8_t *buf, size_t len);

/* Read one whole BGP message into buf (capacity cap). On success sets *type
 * and returns the message length; returns -1 on error. */
int recv_message(int fd, uint8_t *buf, size_t cap, uint8_t *type);

/* Builders return the number of bytes written into buf. */
size_t build_open(uint8_t *buf, uint16_t my_as, uint16_t hold, const uint8_t rid[4]);
size_t build_keepalive(uint8_t *buf);
size_t build_update(uint8_t *buf, const uint8_t nexthop[4], uint16_t my_as);

#endif /* BGP_H */
