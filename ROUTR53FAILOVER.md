# AWS Route 53 Multi-Region Failover with Load Balancer Health Check (Full Step-by-Step Document)

## Objective

You have:

* **Region A (Primary)** → Load Balancer A
* **Region B (DR / Secondary)** → Load Balancer B
* Main Domain:

**ecs.faveodemo.com**

You want:

✅ If Region A is healthy → traffic goes to Region A
✅ If Region A fails → automatically switch to Region B
✅ If Region A recovers → traffic returns to Region A

---

# Recommended Architecture

```text
User
 ↓
ecs.faveodemo.com
 ↓
Route 53 Failover Record
 ↓
Primary Healthy ? → Region A ALB
Else → Region B ALB
```

# FULL SETUP DOCUMENT

# STEP 1 — Create probe.php in Both Regions

Inside both ECS regions:

```php
<?php
http_response_code(200);
echo "OK";
?>
```

Save as:

```text
/var/www/html/probe.php
```

Test:

```text
https://ecs.faveodemo.com/probe.php
```

Should show:

```text
OK
```

---

# STEP 2 — Find Both Load Balancers

## Region A

Example:

```text
faveo-alb-340858728.us-east-1.elb.amazonaws.com
```

## Region B

Example:

```text
faveo-dr-alb-xxxx.us-west-2.elb.amazonaws.com
```

---

# STEP 3 — Create Health Check for Region A

Go AWS:

```text
Route53 → Health Checks → Create
```

---

## Fill:

| Field             | Value                                           |
| ----------------- | ----------------------------------------------- |
| Name              | faveo-primary-health                            |
| Resource Type     | Endpoint                                        |
| Specify by        | Domain Name                                     |
| Protocol          | HTTP                                            |
| Domain Name       | faveo-alb-340858728.us-east-1.elb.amazonaws.com |
| Path              | /probe.php                                      |
| Port              | 80                                              |
| Request Interval  | 30 sec                                          |
| Failure Threshold | 3                                               |

Create.

---

# STEP 4 — Create Health Check for Region B

Same process:

| Field       | Value           |
| ----------- | --------------- |
| Name        | faveo-dr-health |
| Protocol    | HTTP            |
| Domain Name | DR ALB DNS      |
| Path        | /probe.php      |

Create.

---

# STEP 5 — Create Hosted Zone in Route53

Go:

```text
Route53 → Hosted Zones
```

Create zone:

```text
faveodemo.com
```

---

# STEP 6 — Create Failover DNS Record

Go Hosted Zone:

```text
faveodemo.com
```

Create Record.

---

# Record 1 (PRIMARY)

| Field          | Value                                           |
| -------------- | ----------------------------------------------- |
| Name           | ecs                                             |
| Type           | CNAME                                           |
| Value          | faveo-alb-340858728.us-east-1.elb.amazonaws.com |
| TTL            | 60                                              |
| Routing Policy | Failover                                        |
| Failover Type  | Primary                                         |
| Health Check   | faveo-primary-health                            |
| Record ID      | primary                                         |

---

# Record 2 (SECONDARY)

| Field          | Value      |
| -------------- | ---------- |
| Name           | ecs        |
| Type           | CNAME      |
| Value          | DR ALB DNS |
| TTL            | 60         |
| Routing Policy | Failover   |
| Failover Type  | Secondary  |
| Health Check   | Optional   |
| Record ID      | secondary  |

Create records.

---

# FAILOVER WORKING

## Normal

```text
ecs.faveodemo.com
→ Region A
```

## If Region A Down

Health check fails.

After 1–2 mins:

```text
ecs.faveodemo.com
→ Region B
```

## If Region A Back

Auto returns to Region A.

---

# HOW TO TEST FAILOVER

Temporarily stop:

* ECS service
  OR
* ALB target group
  OR
* Rename probe.php

Then Route53 switches.

---

# BEST PRACTICE

Use health check against ALB directly:

```text
http://ALB-DNS/probe.php
```

NOT main domain.

Because main domain itself changes during failover.

---

# Final DNS Flow

```text
ecs.faveodemo.com
   ↓
Route53
   ↓
Primary ALB (healthy)
   ↓
Secondary ALB (if failed)
```

---
