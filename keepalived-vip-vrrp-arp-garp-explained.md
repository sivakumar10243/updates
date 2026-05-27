# Clear Explanation - How Keepalived, VIP, ARP, GARP Work

Let’s understand from the beginning with real traffic flow.

---

# Example Setup

| Server   | Real IP      | MAC Address |
| -------- | ------------ | ----------- |
| Server A | 192.168.1.10 | AA-AA-AA    |
| Server B | 192.168.1.20 | BB-BB-BB    |

Shared VIP:

```text id="jlwm00"
192.168.1.50
```

Applications connect only to:

```text id="jlwm0a"
192.168.1.50
```

---

# 1. What is VIP?

VIP = Virtual IP

It is a floating IP.

It moves between servers.

Example:

```text id="’wini0k"
Sometimes VIP is on Server A
Sometimes VIP is on Server B
```

---

# 2. What is VRRP?

VRRP = election system.

Both servers talk to each other.

They compare priority.

Example:

| Server | Priority |
| ------ | -------- |
| A      | 101      |
| B      | 100      |

Higher priority wins.

So:

```text id="’wini0u"
Server A becomes MASTER
```

---

# 3. How VIP Gets Assigned?

keepalived runs internally:

```bash id="’wini14"
ip addr add 192.168.1.50 dev eth0
```

Meaning:

```text id="’wini1d"
Attach VIP to network card eth0
```

Now Server A owns:

| Type    | IP           |
| ------- | ------------ |
| Real IP | 192.168.1.10 |
| VIP     | 192.168.1.50 |

---

# 4. What is MAC Address?

MAC = physical hardware address of network card.

Example:

| Server | MAC      |
| ------ | -------- |
| A      | AA-AA-AA |
| B      | BB-BB-BB |

Switches send traffic using MAC.

NOT directly using IP.

---

# 5. What is ARP?

ARP = Address Resolution Protocol

ARP converts:

```text id="’wini1m"
IP → MAC
```

---

# 6. How ARP Works?

Application wants DB connection:

```text id="’wini1w"
192.168.1.50:3306
```

Client asks network:

```text id="’wini25"
Who owns 192.168.1.50?
```

Server A replies:

```text id="’wini2f"
I own 192.168.1.50
My MAC is AA-AA-AA
```

Client saves:

| IP           | MAC      |
| ------------ | -------- |
| 192.168.1.50 | AA-AA-AA |

This is called ARP table.

---

# 7. How Traffic Reaches Database?

Traffic flow:

```text id="’wini2q"
Application
   ↓
VIP 192.168.1.50
   ↓
ARP finds MAC AA-AA-AA
   ↓
Switch sends packet to Server A
   ↓
Linux receives packet
   ↓
MariaDB port 3306 reads query
```

---

# 8. What Happens if Server A Fails?

Server A crashes.

VRRP heartbeat stops.

Server B detects:

```text id="’wini31"
MASTER is dead
```

---

# 9. Server B Takes VIP

Server B runs:

```bash id="’wini3a"
ip addr add 192.168.1.50 dev eth0
```

Now Server B owns VIP.

---

# 10. Problem After Failover

Clients still remember old mapping:

| IP           | MAC      |
| ------------ | -------- |
| 192.168.1.50 | AA-AA-AA |

Traffic still goes to dead server.

---

# 11. What is GARP?

GARP = Gratuitous ARP

It is automatic announcement.

Server B broadcasts:

```text id="’wini3k"
192.168.1.50 is NOW on MY MAC BB-BB-BB
```

---

# 12. Network Updates

Old mapping:

```text id="’wini3t"
192.168.1.50 → AA-AA-AA
```

New mapping:

```text id="’wini42"
192.168.1.50 → BB-BB-BB
```

Now traffic goes to Server B.

---

# 13. Traffic After Failover

```text id="’wini4b"
Application
   ↓
VIP 192.168.1.50
   ↓
ARP now points to BB-BB-BB
   ↓
Switch sends packet to Server B
   ↓
MariaDB on Server B reads query
```

---

# COMPLETE FLOW

```text id="’wini4l"
keepalived starts
        ↓
VRRP election happens
        ↓
Highest priority becomes MASTER
        ↓
MASTER assigns VIP
        ↓
MASTER sends GARP
        ↓
Network maps VIP → MASTER MAC
        ↓
Traffic reaches MASTER DB
        ↓
MASTER crashes
        ↓
Heartbeat stops
        ↓
BACKUP becomes MASTER
        ↓
BACKUP assigns VIP
        ↓
BACKUP sends GARP
        ↓
Network maps VIP → BACKUP MAC
        ↓
Traffic moves automatically
```

---

# Final Simple Meaning

| Term       | Meaning                     |
| ---------- | --------------------------- |
| VIP        | Floating IP                 |
| VRRP       | Election system             |
| ARP        | Finds MAC from IP           |
| GARP       | Announces new MAC ownership |
| MAC        | Physical network card ID    |
| keepalived | Controls VIP failover       |

---

# Final One-Line Summary

```text id="’wini4u"
VIP → ARP → MAC → Switch → Server → MariaDB
```

During failover:

```text id="’wini53"
GARP updates VIP-to-MAC mapping automatically.
```

-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
# Why Keepalived VIP HA Will Not Work Between PROD and SCC Subnets

## Network Details

| Environment | Server IP                     | VIP           |
| ----------- | ----------------------------- | ------------- |
| PROD        | 10.202.17.183 / 10.202.17.186 | 10.202.17.187 |
| SCC         | 10.201.17.183 / 10.201.17.185 | 10.201.17.187 |

---

# Main Reason

The PROD and SCC networks are in different subnets:

```text id="jlwm00"
PROD → 10.202.17.0/24
SCC  → 10.201.17.0/24
```

Keepalived VRRP works properly only when:

* both servers are in same subnet
* same VLAN
* same Layer-2 network

---

# Why Same Subnet Is Required

Keepalived failover depends on:

1. VIP assignment
2. ARP/GARP announcement
3. MAC address update

ARP and GARP work only inside the local subnet/network.

---

# How Keepalived Normally Works

## Example

PROD server owns VIP:

```text id="’wini0a"
10.202.17.187
```

Network mapping becomes:

```text id="’wini0k"
10.202.17.187 → MAC of PROD server
```

Traffic reaches PROD correctly.

---

# What Happens During Failover

If PROD fails and SCC tries to take VIP:

```text id="’wini0u"
10.202.17.187 → MAC of SCC server
```

But SCC server belongs to:

```text id="’wini14"
10.201.17.x network
```

Routers and switches in PROD network still expect:

```text id="’wini1d"
10.202.17.187
```

to exist only inside:

```text id="’wini1m"
10.202.17.x subnet
```

So:

* ARP/GARP updates will not propagate correctly
* traffic may still go to old PROD side
* VIP routing becomes unreliable
* failover may fail completely

---

# Technical Reason

VRRP failover is based on:

* ARP
* Gratuitous ARP (GARP)
* MAC address movement

ARP works only within the same broadcast domain/subnet.

Different routed subnets cannot properly share one floating VIP using standard keepalived.

---

# Correct Design

Use separate VIPs per subnet:

| Environment | VIP           |
| ----------- | ------------- |
| PROD        | 10.202.17.187 |
| SCC         | 10.201.17.187 |

Then:

* local keepalived HA inside each subnet
* DNS/load balancer/application-level failover between PROD and SCC

---

# Final Conclusion

Standard keepalived VRRP HA will not work reliably between:

```text id="’wini1w"
10.202.17.x
and
10.201.17.x
```

because they are different subnets, and VRRP failover depends on ARP/GARP, which only work correctly within the same local Layer-2 network/subnet.
