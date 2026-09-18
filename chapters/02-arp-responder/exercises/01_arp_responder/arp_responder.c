// I AM NOT DONE
#include <arpa/inet.h>
#include <linux/if_ether.h>
#include <linux/if_packet.h>
#include <net/if.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <unistd.h>

#define ARP_OP_REQUEST 1
#define ARP_OP_REPLY 2

static struct in_addr g_virtual_ip;

/* 构造并发送 ARP 应答：以收到请求的 sender_mac 作为回包源 MAC，
 * 把 target_ip 的 MAC 宣告为 sender_mac。
 * 返回 0 成功，非 0 失败。 */
static int send_arp_reply(int fd, int ifindex,
                          const unsigned char *our_mac,
                          const unsigned char *sender_mac, struct in_addr sender_ip,
                          struct in_addr target_ip) {
    /* TODO(learner): 实现 ARP 应答帧的构造与 sendto。 */
    return -1;
}

/* 处理一个以太网帧；返回 0 正常。 */
static int handle_packet(int fd, int ifindex, const unsigned char *buf, ssize_t len) {
    /* TODO(learner): 解析 Ethernet + ARP，若为对 g_virtual_ip 的请求则调用 send_arp_reply。 */
    return 0;
}

int main(int argc, char **argv) {
    const char *ifname = "eth1";
    const char *vip = "10.0.1.1";
    for (int i = 1; i < argc; i++) {
        if (strcmp(argv[i], "--iface") == 0 && i + 1 < argc) ifname = argv[++i];
        else if (strcmp(argv[i], "--ip") == 0 && i + 1 < argc) vip = argv[++i];
    }

    int ifindex = if_nametoindex(ifname);
    if (ifindex == 0) { perror("if_nametoindex"); return 1; }
    inet_aton(vip, &g_virtual_ip);

    int fd = socket(AF_PACKET, SOCK_RAW, htons(ETH_P_ARP));
    if (fd < 0) { perror("socket"); return 1; }

    struct sockaddr_ll sll = {0};
    sll.sll_family = AF_PACKET;
    sll.sll_protocol = htons(ETH_P_ARP);
    sll.sll_ifindex = ifindex;
    if (bind(fd, (struct sockaddr *)&sll, sizeof(sll)) < 0) { perror("bind"); return 1; }

    unsigned char buf[2048];
    for (;;) {
        ssize_t n = recv(fd, buf, sizeof(buf), 0);
        if (n <= 0) continue;
        handle_packet(fd, ifindex, buf, n);
    }
    return 0;
}
