// I AM NOT DONE
#include "bgp.h"

#include <arpa/inet.h>
#include <errno.h>
#include <netinet/in.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

#define MY_AS 65001
#define HOLD 90

/* ---- helpers (already done) ---- */

static void put16(uint8_t *p, uint16_t v) { p[0] = (uint8_t)(v >> 8); p[1] = (uint8_t)v; }
static void put32(uint8_t *p, uint32_t v) {
    p[0] = (uint8_t)(v >> 24); p[1] = (uint8_t)(v >> 16);
    p[2] = (uint8_t)(v >> 8); p[3] = (uint8_t)v;
}

int tcp_connect(const char *host, uint16_t port) {
    int fd = socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) return -1;
    struct sockaddr_in sa;
    memset(&sa, 0, sizeof sa);
    sa.sin_family = AF_INET;
    sa.sin_port = htons(port);
    if (inet_pton(AF_INET, host, &sa.sin_addr) != 1) { close(fd); return -1; }
    if (connect(fd, (struct sockaddr *)&sa, sizeof sa) != 0) { close(fd); return -1; }
    return fd;
}

int send_all(int fd, const uint8_t *buf, size_t len) {
    size_t off = 0;
    while (off < len) {
        ssize_t n = send(fd, buf + off, len - off, 0);
        if (n <= 0) return -1;
        off += (size_t)n;
    }
    return 0;
}

int recv_message(int fd, uint8_t *buf, size_t cap, uint8_t *type) {
    size_t got = 0;
    while (got < 19) {
        ssize_t n = recv(fd, buf + got, 19 - got, 0);
        if (n <= 0) return -1;
        got += (size_t)n;
    }
    uint16_t len = (uint16_t)((buf[16] << 8) | buf[17]);
    if (len < 19 || len > cap) return -1;
    while (got < len) {
        ssize_t n = recv(fd, buf + got, len - got, 0);
        if (n <= 0) return -1;
        got += (size_t)n;
    }
    *type = buf[18];
    return (int)len;
}

/* ---- protocol (implement these) ---- */

size_t build_open(uint8_t *buf, uint16_t my_as, uint16_t hold, const uint8_t rid[4]) {
    /* TODO: 19-byte header (marker all ones, length 29, type 1) followed by
     * version 4, my_as, hold, rid, and a zero optional-parameters length. */
    (void)my_as; (void)hold; (void)rid;
    return 0;
}

size_t build_keepalive(uint8_t *buf) {
    /* TODO: 19-byte header only (marker all ones, length 19, type 4). */
    return 0;
}

size_t build_update(uint8_t *buf, const uint8_t nexthop[4], uint16_t my_as) {
    /* TODO: header (type 2), withdrawn routes length 0, path attributes
     * ORIGIN + AS_PATH (one 2-byte AS) + NEXT_HOP, then NLRI 192.0.2.0/24. */
    (void)nexthop; (void)my_as;
    return 0;
}

int main(int argc, char **argv) {
    /* TODO: connect, send OPEN, recv peer OPEN, send KEEPALIVE, recv peer
     * KEEPALIVE (Established), send UPDATE advertising 192.0.2.0/24, then send
     * a KEEPALIVE every HOLD/3 seconds. */
    if (argc < 2) {
        fprintf(stderr, "usage: %s <peer-ip>\n", argv[0]);
        return 2;
    }
    fprintf(stderr, "not implemented yet\n");
    return 1;
}
