# 01_advertise

`r1` (AS 65001, 10.1.12.1/30) and `r2` (AS 65002, 10.1.12.2/30) are Established,
and `r1` has `network 192.0.2.0/24`, yet `r2` never learns the prefix.

## Cause

FRR requires a policy for eBGP by default. The session is healthy, but `show bgp
summary` shows `peerState` `Policy` and `pfxSnt 0`: no UPDATE leaves r1.

## Observe

```sh
docker exec -it <r1> vtysh -c 'show bgp summary'
```

`peerState` `Policy` with `pfxSnt 0` confirms the policy is blocking advertisement.

## Fix

```sh
docker exec <r1> vtysh -c 'conf t' -c 'router bgp 65001' -c 'no bgp ebgp-requires-policy'
docker exec <r1> vtysh -c 'clear bgp *'
```

Existing UPDATEs are not resent after a configuration change; `clear bgp *`
rebuilds the session and sends the prefix again. Check r2:

```sh
docker exec <r2> vtysh -c 'show bgp ipv4 unicast'
```

Press Enter to verify; `f` re-injects the fault.
