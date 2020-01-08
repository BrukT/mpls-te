# Differentiated Service Architecture using MPLS for QoS support 

## Network Architecture

The network is built and configured with [GNS3](https://www.gns3.com) ide. It is recommended to use the same software for testing it. 

![Scenario](/doc/img/gns3.png)

The above scenario shows three networks interconnected through a core network of 5 routers. Each network contains either _Client_ nodes (`A1`, `A2`, `C1`) or _Server_ nodes (`B1`, `B2`). Clients send data to servers and have the flow characteristics that are shown in the following table:

| Source | Destination | Priority | Bandwidth |
--- | --- | --- | ---
A1 | B1 | High | 0.9Mbps
A2 | B2 | Low | 1.2Mbps
C1 | B1 | High | 0.9Mbps

### Goals

- Each flow conforms to the characteristics of the above able. For high-priority flows, the excess traffic is downgraded to low priority; for low-priority flows, the excess traffic is dropped.

- Each high-priority flow is granted at worst 60% of the bandwidth for the link it traverses in the core network.

## Configuration

The following table represents the address assignation for the networks:

| Net | Address | Subnet mask |
--- | --- | ---
A | 10.0.1.0 | 255.255.255.0
B | 10.0.2.0 | 255.255.255.0
C | 10.0.3.0 | 255.255.255.0
R1-R3 | 172.16.0.0 | 255.255.255.252
R1-R2 | 172.16.4.0 | 255.255.255.252
R3-R4 | 172.16.8.0 | 255.255.255.252
R4-R5 | 172.16.12.0 | 255.255.255.252
R2-R5 | 172.16.16.0 | 255.255.255.252

For the IPs assigned to the router interfaces you can refer to the picture shown above.

In order to achive the flow characteristics, we decided to configure the IP address of hosts in `Network-A` and `Network-B` statically. Instead we configured DHCP service on `R2` since it has only one host in its subnetwork.

Futhermore, as shown in the next table, for each router we configured the `Loopback0` interface with IP mask of 32 bits, which will be used as `router-id` attribute in the OSPF protocol.

| Router | Loopback IP address |
--- | ---
R1 | 172.16.1.1
R2 | 172.16.1.2
R3 | 172.16.1.3
R4 | 172.16.1.4
R5 | 172.16.1.5

### OSPF

We chose OSPF as routing protocol since it is ready for the implementation of _MPLS-TE_.

Every router has been configured in order to be able to announce all the network to which it is attached, included the `Loopback0`:

```
R(config)# router ospf 1
R(config-router)# network <network-address> <wildcard-mask> area 0
```

### Packet Classification

In order to classificate the flows based on source and destination we used _Extendend Access Control Lists_ and we put them in the nearest router to the source. Thus, we defined three ACLs accordingly to the three different flows we have to match.

On `R1` we defined an ACL with id `121` for traffic from `A1` to `B1`:

```
R1(config)# access-list 121 permit ip host 10.0.1.2 host 10.0.2.2
R1(config)# class-map match-all A1B1
R1(config-cmap)# match access-group 121
```

and an ACL with id `122` for traffic from `A2` to `B2`:

```
R1(config)# access-list 122 permit ip host 10.0.1.3 host 10.0.2.3
R1(config)# class-map match-all A2B2
R1(config-cmap)# match access-group 122
```

On `R2` we defined an ACL with id `121` for traffic from `C1` to `B1`:

```
R2(config)# access-list 121 permit ip host 10.0.3.2 host 10.0.2.2
R2(config)# class-map match-all C1B1
R2(config-cmap)# match access-group 121
```

### Packet Marking

For differentiating the two types of flow we assigned different _Per Hob Behavior_ as shown in the following table:

| Priority | PHB | DSCP |
--- | --- | ---
High | EF | 46
Low | AF13 | 14

In the relative routers we defined marking for the classes. On `R1` for high-priority flow:

```
R1(config)# policy-map E00
R1(config-pmap)# class A1B1
R1(config-pmap-c)#set ip dscp ef
```

and for low-priority flow:

```
R1(config)# policy-map E00
R1(config-pmap)# class A2B2
R1(config-pmap-c)#set ip dscp af13
```

On `R2`:

```
R2(config)# policy-map E00
R2(config-pmap)# class C1B1
R2(config-pmap-c)#set ip dscp ef
```

Then we mapped in _input_ the defined policies to the `ethernet 0/0` interfaces on both routers:

```
R(config)# interface ethernet 0/0
R(config-if)# service-policy input E00
```

### Packet Policing

In order to meet the requirements about the excess traffic we defined policing rules by means of _Committed Access Rate_ (CAR) at the input of `R1` and `R2` on `ethernet 0/0` interface.

On `R1` and `R2`, for `A1` to `B1` and `C1` to `B1` traffic, respectively, defined by ACL `121`, we have to downgrade the excess traffic to low-priority:

```
R(config-if)# rate-limit input access-group 121 900000 5000 5000 conform-action continue exceed-action set-dscp-transmit 14
```

and only on `R1` for `A2` to `B2` traffic defined by ACL `122` we have to drop packets belonging to exceeded traffic:

```
R1(config-if)# rate-limit input access-group 122 1200000 5000 5000 conform-action continue exceed-action set-dscp-transmit drop
``` 

### Class-based Weighted Fair Queuing

Finally we configured all routers in the network in order to make them able to classify different traffic classes based on DSCP and to allocate the wanted bandwidth for each of them.

Since we have to reserve at least 60% of bandwidth for the high-priority flows we need only to match `EF` PHB.
For classifying the flow based on DSCP:

```
R(config)# class-map match-all HIGH
R(config-cmap)# match dscp ef
```

For allocating 60% of bandwidth:

```
R(config)# policy-map OUT
R(config-pmap)# class HIGH
R(config-pmap-c)# bandwidth percent 60
```

For associating the policy to every `serial` interface:

```
R(config-if)# service-policy output OUT
```

### MPLS-TE

Since now, every traffic from `Network-A` to `Network-B` and from `Network-C` to `Network-B` is passing through `R2-R5` link based on OSPF best path. But by requirements, we have to guarantee at least 60% of bandwidth to high-priority flows. If both of them share `R2-R5` link at the same moment, this requirement can not be met.

Furthermore the links involving `R1-R3-R4-R5` are never used since they represent the longest path for every traffic among the three stub networks.

Thus, for meeting the bandwidth requirement and avoiding the under-utilization of some network parts, we used _MPLS-TE_ which allows us to support constrained-based routing.

First, we enabled _Cisco Express Forwarding_ (CEF) and _tag switching_ on every interface of every router involved, in our case all of them but `R2`:

```
R(config)# ip cef
R(config)# interface <interf>
R(config-if)# mpls ip
```

Then we made routers able to create _traffic engineering tunnels_ (_MPLS Label Switched Paths_) to steer traffic through the network allowing links not included in the shortes path to be used:

1. Enable tunnels creation:

```
R(config)# mpls traffic-eng tunnels
```

2. Enable TE extension on OSPF:

```
R(config)# router ospf 1
R(config-router)# mpls traffic-eng area 1
R(config-router)# mpls traffic-eng router-id Loopback0
```

3. Enable MPLS tunnel creation on the interfaces specifying the reservable bandwidth and the largest reservable flow on the interface:

```
R(config)# interface <interf>
R(config-if)# mpls traffic-eng tunnels
R(config-if)# ip rsvp bandwidth 512 512
```

Finally, on the ingress router `R1`, we created `Tunnel0` with `172.16.1.5` as destination and the explicit path:

```
R1(config)# interface Tunnel1
R1(config-if)# ip unnumbered Loopback0
R1(config-if)# tunnel destination 172.16.1.5
R1(config-if)# tunnel mode mpls traffic-eng
R1(config-if)# tunnel mpls traffic-eng autoroute announce
R1(config-if)# tunnel mpls traffic-eng priority 2 2
R1(config-if)# tunnel mpls traffic-eng path-option 1 explicit name longpath
R1(config-if)# tunnel mpls traffic-eng path-option 2 dynamic
```

The explict path `longpath` has been defined as follows:

```
R1(config)# ip explict-path name longpath enable
R1(cfg-ip-expl-path)# next-address 172.16.0.2
R1(cfg-ip-expl-path)# next-address 172.16.0.10
R1(cfg-ip-expl-path)# next-address 172.16.0.14
```
### Fulfilling the constraint
send the traffic from `A2` to `B2` through `R2` by setting the routing of the specific destination and the next hop in `R1`.
```
R1(config)# ip route 10.0.2.3 255.255.255.255 172.16.0.6
```
 
## Troubleshooting

Use the following commands on the end-point consoles to test the resulting traffic load.

On servers:   
```
iperf -u -s -i 1
```

On clients:  

``` 
iperf -u -c <server-ip-address> -i 1 -b <data-size> -t 30
```

The `<data-size>` can be set to various ranges from small to large to see the run time bandwidth of each flow.

## Clone repository

In order to clone this repository you need to have the Git Large File Storage installed on your machine. Also you have to instantiate your working directory with `git lfs` by: 

```
git lfs install
```

For pulling for the first time the all content of the repo after the clone, you need to issue:

```
git lfs pull
```
